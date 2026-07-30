{
  description = "Carmilla's desktop config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-compat.url = "github:NixOS/flake-compat/master";

    rust-overlay = {
      url = "github:oxalica/rust-overlay/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
      inputs.pre-commit.inputs.flake-compat.follows = "flake-compat";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    aagl = {
      url = "github:ezKEa/aagl-gtk-on-nix/main";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
      inputs.flake-compat.follows = "flake-compat";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager/trunk";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    nixvim,
    nix-darwin,
    impermanence,
    lanzaboote,
    sops-nix,
    ...
  } @ inputs: let
    overlays = import ./overlays.nix;

    pkgsFor = system:
      import nixpkgs {
        inherit system;
        overlays = [overlays.additions overlays.modifications];
        config.allowUnfree = true;
      };

    # The home-manager settings both platforms share; every user gets the nixvim home module.
    homeManagerSettings = {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "bak";
        sharedModules = [nixvim.homeModules.nixvim];
      };
    };
  in {
    formatter = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-darwin"] (system: nixpkgs.legacyPackages.${system}.alejandra);

    # tibia, the only package here, builds for x86_64-linux alone.
    packages.x86_64-linux = import ./pkgs (pkgsFor "x86_64-linux");

    nixosConfigurations.camellya = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        {nixpkgs.pkgs = pkgsFor "x86_64-linux";}
        impermanence.nixosModules.impermanence
        lanzaboote.nixosModules.lanzaboote
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        homeManagerSettings
        ./hosts/camellya
        ./users/carmilla
      ];
    };

    darwinConfigurations.silverwolf = nix-darwin.lib.darwinSystem {
      specialArgs = {inherit inputs;};
      modules = [
        {nixpkgs.pkgs = pkgsFor "aarch64-darwin";}
        home-manager.darwinModules.home-manager
        homeManagerSettings
        ./hosts/silverwolf
        ./users/carmilla
      ];
    };
  };
}
