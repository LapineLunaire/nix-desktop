# Nix settings shared by NixOS (modules/nixos/host-base) and nix-darwin (modules/darwin).
{...}: {
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      flake-registry = ""; # an empty path disables the global flake registry
      auto-optimise-store = true;
    };
    channel.enable = false;
  };
}
