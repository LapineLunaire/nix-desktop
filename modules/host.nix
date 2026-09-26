{lib, ...}: {
  options.host.flakePath = lib.mkOption {
    type = lib.types.str;
    description = "Flake checkout used by nh.";
  };
}
