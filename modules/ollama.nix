{ pkgs, lib, config, ... }:
let
  cfg = config.machines.${config.networking.hostName}.ollama;

  inherit (pkgs) stdenvNoCC python3 llama-cpp;

  # https://huggingface.co/girldickgay/fedi-persona-qwen3.5-9b is a LoRA adapter
  # only, so we download the base model, merge the adapter in, convert to GGUF,
  # and quantize to each `quants` entry, registered as `fedi-persona:<tag>`. To
  # bump a download: set `rev`, reset its `hash` to lib.fakeHash, build, and
  # paste the "got: sha256-..." Nix reports.

  baseRepo = "Qwen/Qwen3.5-9B";
  adapterRepo = "girldickgay/fedi-persona-qwen3.5-9b";
  quants = [ "Q8_0" "Q4_K_M" "Q2_K" ];

  fetchHfRepo = { repo, rev, hash, excludes ? [ ] }:
    stdenvNoCC.mkDerivation {
      name = "hf-${builtins.replaceStrings [ "/" ] [ "-" ] repo}";
      nativeBuildInputs = [ python3.pkgs.huggingface-hub ];
      dontUnpack = true;
      buildPhase = ''
        export HF_HOME="$TMPDIR/hf"
        hf download ${repo} --revision ${rev} --local-dir "$out" \
          ${lib.concatMapStringsSep " " (e: ''--exclude "${e}"'') excludes}
        # The CLI leaves a non-reproducible metadata cache behind.
        rm -rf "$out/.cache"
      '';
      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      outputHash = hash;
    };

  baseModel = fetchHfRepo {
    repo = baseRepo;
    rev = "c202236235762e1c871ad0ccb60c8ee5ba337b9a";
    hash = "sha256-2d8gpIZ55UJ3W3Q81iAzoFfsk2mKR1Yz43hi5GzFOq8=";
  };

  adapter = fetchHfRepo {
    repo = adapterRepo;
    rev = "8e8340e5b2aca1d67cfd13ae80114b62b0ea0a29";
    hash = "sha256-hB/yz70Y1yadmt3zG20l7NYuDdCPxnkqoy03ULs+duA=";
  };

  mergePython = python3.withPackages (ps: with ps; [
    torch
    safetensors
  ]);

  convertPython = python3.withPackages (ps: with ps; [
    torch
    transformers
    gguf
    numpy
    sentencepiece
    protobuf
    safetensors
  ]);

  # Text-only LoRA on a vision-language base: fold it into the text weights
  # shard-by-shard (peak RAM ~one shard) and let the converter extract the text
  # model. peft would instead load the whole model and OOM.
  mergeScript = pkgs.writeText "merge-lora.py" ''
    import sys, os, json, shutil
    from collections import defaultdict
    import torch
    from safetensors import safe_open
    from safetensors.torch import save_file

    base_path, adapter_path, out_path = sys.argv[1], sys.argv[2], sys.argv[3]

    cfg = json.load(open(os.path.join(adapter_path, "adapter_config.json")))
    assert not cfg.get("use_rslora") and not cfg.get("use_dora"), "unsupported LoRA variant"
    assert not cfg.get("fan_in_fan_out"), "fan_in_fan_out not supported"
    scaling = cfg["lora_alpha"] / cfg["r"]

    # Map base weight key -> {A, B} from the adapter (small, ~230 MB).
    loras = defaultdict(dict)
    with safe_open(os.path.join(adapter_path, "adapter_model.safetensors"), "pt") as f:
        for k in f.keys():
            bk = k.replace("base_model.model.", "", 1)
            if bk.endswith(".lora_A.weight"):
                loras[bk[:-len(".lora_A.weight")] + ".weight"]["A"] = f.get_tensor(k)
            elif bk.endswith(".lora_B.weight"):
                loras[bk[:-len(".lora_B.weight")] + ".weight"]["B"] = f.get_tensor(k)

    os.makedirs(out_path, exist_ok=True)
    index = json.load(open(os.path.join(base_path, "model.safetensors.index.json")))
    shards = set(index["weight_map"].values())

    # Copy everything that isn't a weight shard (config, tokenizer, index, ...).
    for name in os.listdir(base_path):
        src = os.path.join(base_path, name)
        if os.path.isfile(src) and name not in shards:
            shutil.copy(src, os.path.join(out_path, name))

    by_shard = defaultdict(list)
    for key, shard in index["weight_map"].items():
        by_shard[shard].append(key)

    merged = 0
    for shard, keys in by_shard.items():
        tensors = {}
        with safe_open(os.path.join(base_path, shard), "pt") as f:
            for key in keys:
                t = f.get_tensor(key)
                lo = loras.get(key)
                if lo and "A" in lo and "B" in lo:
                    delta = (lo["B"].float() @ lo["A"].float()) * scaling
                    t = (t.float() + delta).to(t.dtype)
                    merged += 1
                tensors[key] = t
        save_file(tensors, os.path.join(out_path, shard), metadata={"format": "pt"})

    assert merged == len(loras), f"merged {merged} of {len(loras)} LoRA layers"
    print(f"merged {merged} LoRA layers into {len(by_shard)} shards")
  '';

  # Merge + convert to f16 once, then quantize to each `quants` entry. Only the
  # quantized files are kept; the f16 stays in the build sandbox.
  ggufs = stdenvNoCC.mkDerivation {
    pname = "fedi-persona-qwen3.5-9b-gguf";
    version = "0.1";
    dontUnpack = true;
    buildPhase = ''
      export HF_HUB_OFFLINE=1
      export TRANSFORMERS_OFFLINE=1

      echo "merging LoRA adapter into base model..."
      mkdir -p merged
      ${mergePython}/bin/python ${mergeScript} \
        ${baseModel} ${adapter} "$PWD/merged"

      echo "converting to f16 GGUF..."
      ${convertPython}/bin/python ${llama-cpp.src}/convert_hf_to_gguf.py \
        "$PWD/merged" --outfile "$PWD/model-f16.gguf" --outtype f16

      mkdir -p "$out"
      ${lib.concatMapStringsSep "\n" (q: ''
        echo "quantizing to ${q}..."
        ${llama-cpp}/bin/llama-quantize \
          "$PWD/model-f16.gguf" "$out/${lib.toLower q}.gguf" ${q}
      '') quants}
    '';
  };

  fediVariants = map
    (q: rec {
      tag = lib.toLower q;
      model = "fedi-persona:${tag}";
      unit = "ollama-fedi-persona-${tag}"; # systemd-safe name (no colon)
      modelfile = pkgs.writeText "fedi-persona-${tag}.modelfile" ''
        FROM ${ggufs}/${tag}.gguf
      '';
    })
    quants;

  # SmolLM3-3B isn't in the Ollama library, so we pin the prebuilt GGUF and
  # register it ourselves.
  smollm3Gguf = pkgs.fetchurl {
    url = "https://huggingface.co/ggml-org/SmolLM3-3B-GGUF/resolve/main/SmolLM3-Q8_0.gguf";
    hash = "sha256-iqjMdGVhNxdKGYjZk7AIKOZahv1odzQStjKnWqE3Mkg=";
  };

  smollm3Modelfile = pkgs.writeText "smollm3.modelfile" ''
    FROM ${smollm3Gguf}
  '';

  # `loadModels` only does `ollama pull`, which can't fetch a locally built or
  # pinned GGUF, so register those via `ollama create` once the server is up.
  # Inherit ollama.service's environment (HOME/OLLAMA_MODELS/OLLAMA_HOST) and
  # DynamicUser, matching upstream's model-loader: the CLI talks to the server
  # over the API but panics with "$HOME is not defined" without those vars.
  mkRegisterService = model: modelfile: lib.mkIf cfg.enable {
    description = "Register ${model} model with Ollama";
    wantedBy = [ "multi-user.target" ];
    after = [ "ollama.service" ];
    bindsTo = [ "ollama.service" ];
    environment = config.systemd.services.ollama.environment;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      DynamicUser = true;
      ExecStart = pkgs.writeShellScript "create-${lib.replaceStrings [ ":" ] [ "-" ] model}" ''
        set -eu
        # Wait for the ollama server to accept connections.
        for _ in $(seq 1 60); do
          ${config.services.ollama.package}/bin/ollama list >/dev/null 2>&1 && break
          sleep 1
        done
        ${config.services.ollama.package}/bin/ollama create ${model} -f ${modelfile}
      '';
    };
  };
in
{
  # environment.systemPackages = [ pkgs.ollama ];
  services.ollama = {
    enable = cfg.enable;
    package = pkgs."ollama-${cfg.package}";
    environmentVariables = {
      ROCR_VISIBLE_DEVICES = "0";
      OLLAMA_FLASH_ATTENTION = "1";
      # Smaller KV cache keeps more layers on the 8 GB GPU.
      OLLAMA_KV_CACHE_TYPE = "q8_0";
      # Single-user: don't split 8 GB across parallel slots / multiple models.
      OLLAMA_NUM_PARALLEL = "1";
      OLLAMA_MAX_LOADED_MODELS = "1";
      OLLAMA_KEEP_ALIVE = "30m";
    };
    # Optional: preload models, see https://ollama.com/library
    # (SmolLM3-3B would belong here but isn't on Ollama — built separately above.)
    loadModels = [ "qwen3.5:2b" "qwen3.5:9b" "qwen3.6:35b-a3b" ];
  };

  systemd.services = lib.mkMerge [
    (lib.listToAttrs (map
      (v: lib.nameValuePair v.unit (mkRegisterService v.model v.modelfile))
      fediVariants))
    {
      ollama-fedi-persona = mkRegisterService "fedi-persona"
        (builtins.head fediVariants).modelfile;
      ollama-smollm3 = mkRegisterService "smollm3" smollm3Modelfile;
    }
  ];
}
