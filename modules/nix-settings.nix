# Nix settings shared by NixOS (modules/nixos/host-base) and nix-darwin (modules/darwin).
{...}: {
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # An empty value disables the global flake registry, leaving only this flake's pinned inputs.
      flake-registry = "";
      # Replaces store files with identical contents by hard links.
      auto-optimise-store = true;
    };
    channel.enable = false;
  };
}
