{ lib }: rec {
  # splitStringIntoChunks = str -> int -> [str]
  splitStringIntoChunks = str: maxLength:
    let
      numberOfChunks = 1 + (((builtins.stringLength str) - 1) / maxLength);
    in
    builtins.map (i: builtins.substring (i * maxLength) maxLength str) (lib.range 0 (numberOfChunks - 1));

  # Quote a string and split it into chunks for a TXT record
  # quoteTxtEntry = str -> str
  quoteTxtEntry = str:
    let
      chunks = splitStringIntoChunks str 250;
    in
    builtins.concatStringsSep " " (builtins.map (s: "\"" + s + "\"") chunks);
}
