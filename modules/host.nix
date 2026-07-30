# The host option namespace, platform-neutral so the NixOS and the darwin base both read it as config.host.*.
{lib, ...}: {
  options.host.flakePath = lib.mkOption {
    type = lib.types.str;
    description = "Path of this system's flake checkout, which nh builds from.";
  };
}
