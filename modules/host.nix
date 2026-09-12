# The host.* namespace, platform-neutral so both the NixOS and the darwin base read it.
{lib, ...}: {
  options.host = {
    flakePath = lib.mkOption {
      type = lib.types.str;
      description = "Path of this system's flake checkout, which nh builds from.";
    };

    cpu.march = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "GCC microarchitecture target for Linux kernel builds. Null uses the stock package for the selected kernel series. An explicit target keeps builds reproducible across build machines.";
    };

    binaryCache = {
      caches = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            url = lib.mkOption {
              # The netrc renderer supports HTTPS DNS hosts, without userinfo or ports.
              type = lib.types.strMatching "https://[A-Za-z0-9][A-Za-z0-9.-]*(/[A-Za-z0-9._~/?=&%+-]*)?";
              description = "HTTPS substituter URL with a DNS hostname and optional path/query; no userinfo or port.";
            };

            publicKey = lib.mkOption {
              type = lib.types.str;
              description = "The cache's public key in the name:base64 form trusted-public-keys takes, read off `attic cache info`.";
            };
          };
        });
        default = [];
        description = "Attic caches this system substitutes from, beyond cache.nixos.org.";
      };

      tokenSecret = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Name of the sops secret holding the pull token, rendered into the netrc nix authenticates with. Null when no cache is declared.";
      };
    };
  };
}
