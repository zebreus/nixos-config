{ pkgs, config, ... }:
let
  cfg = config.machines.${config.networking.hostName}.ollama;
in
{
  # environment.systemPackages = [ pkgs.ollama ];
  services.ollama = {
    enable = cfg.enable;
    # Optional: preload models, see https://ollama.com/library
    loadModels = [ "llama3.2:3b" "deepseek-r1:1.5b" "deepseek-r1:7b" "deepseek-r1:70b" ];
    acceleration = cfg.acceleration;
  };
}
