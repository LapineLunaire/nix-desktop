# nix-desktop

NixOS and nix-darwin configuration for my desktop and MacBook.

| Host | Platform | Checkout |
|------|----------|----------|
| camellya | x86_64-linux | `/persist/nix-config` |
| silverwolf | aarch64-darwin | `~/projects/nix-config` |

## Usage

Run from the host's checkout:

```sh
nh os switch .      # camellya
nh darwin switch .  # silverwolf
```

`nix develop` provides the formatter, language server, and secrets tools. It also enables the Git formatting hook for this clone. `.envrc` loads the same shell through direnv.

```sh
alejandra .
nix flake check --all-systems --no-build
nix eval .#darwinConfigurations.silverwolf.config.system.build.toplevel.drvPath
nix build .#tibia
```

On Camellya, the `sops` shell alias reads the host key through doas:

```sh
sops hosts/camellya/secrets.yaml
```

See [installation and recovery setup](docs/install.md) for disk layout, keys, Secure Boot, and TPM enrollment.

## Layout

- `hosts/`: machine-specific hardware, filesystems, persistence, secrets, and applications. Camellya's cache and CPU target are configured here.
- `modules/`: shared Nix settings and OS defaults. The flake exports the NixOS and Darwin modules for reuse.
- `users/carmilla/`: account and Home Manager configuration, plus wallpapers.
- `pkgs/`: the Tibia package; `overlays.nix` adds it and the application overrides.

## Conventions

Use Alejandra and keep bindings near their consumers. Use ordinary `let` bindings for shared values; reserve imports for separate modules. Imports come first; related options stay together. Comments explain workarounds and choices that the code alone does not make clear. Commit subjects use `scope: description`.

## Host notes

- Camellya has a tmpfs root, `/tmp`, and `/var/tmp`. Persistent state is listed in `hosts/camellya/persistence.nix`; `/home` has its own filesystem.
- Its kernel targets Zen 5 explicitly so other machines can build it. To use the stock kernel, replace the override with `pkgs.linuxPackages_7_2`.
- uutils is preferred interactively; package dependencies retain GNU utilities.
- The RODECaster routing is generated as JSON in a private SOPS template. Its serial stays out of the generated store file. PipeWire accepts [standard JSON configuration](https://docs.pipewire.org/page_man_pipewire_conf_5.html).
- Wallpaper paths point to the checkout. Home Manager writes the MIME and monitor settings as writable copies; rebuilds restore the declared values.
