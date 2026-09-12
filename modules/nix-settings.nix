{...}: {
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # nix-darwin defaults this to false; isolate builds on both platforms.
      sandbox = true;
      # Disable the global flake registry. The system nixpkgs pin and user registry entries still apply.
      flake-registry = "";
      auto-optimise-store = true;
      # Fall back to a local build after a failed substitute download.
      fallback = true;
    };
    channel.enable = false;
  };
}
