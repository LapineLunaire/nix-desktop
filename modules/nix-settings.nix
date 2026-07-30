# Nix settings shared by NixOS (modules/nixos/host-base) and nix-darwin (modules/darwin).
{...}: {
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      flake-registry = ""; # disable global registry, only use pinned inputs
      auto-optimise-store = true; # hardlink identical files in the store after each build
    };
    channel.enable = false;
  };
}
