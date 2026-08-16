# The host.* namespace, platform-neutral so both the NixOS and the darwin base read it.
{lib, ...}: {
  options.host.flakePath = lib.mkOption {
    type = lib.types.str;
    description = "Path of this system's flake checkout, which nh builds from.";
  };
}
