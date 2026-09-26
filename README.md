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

`nix develop` provides the formatter, language server, and secrets tools, and enables the formatting hook for this clone. The hook checks staged Nix files; if Alejandra is unavailable, it warns and skips the check. Run `direnv allow` to load the same shell through `.envrc`.

```sh
alejandra .
nix flake check --all-systems --no-build --no-write-lock-file --option allow-import-from-derivation false
nix eval --no-write-lock-file --raw '.#darwinConfigurations.silverwolf.config.system.build.toplevel.drvPath'
nix build '.#tibia'  # x86_64-linux only
```

`nix flake check --no-build` and `nix eval` evaluate configuration and derivations; they do not build or activate either system. Silverwolf's toplevel is evaluated explicitly because `nix flake check` does not evaluate the systems under `darwinConfigurations`. Build and activation checks belong on the appropriate platform.

On Camellya, the `sops` shell alias reads the host key through doas:

```sh
sops hosts/camellya/secrets.yaml
```

See [installation and recovery setup](docs/install.md) for disk layout, keys, Secure Boot, and TPM enrollment.

## Automated updates

The Forgejo workflow runs daily at 04:00 UTC (`0 4 * * *`) or manually. [Schedules use UTC by default](https://forgejo.org/docs/v15.0/user/actions/reference/#onschedule). Both jobs use the shared `nixos` host runner configured in `nix-server`.

The Tibia job refreshes the unversioned download's hash. On a change, it builds Tibia, then signs and pushes the update. The flake-update job waits for Tibia to succeed, checks out the branch again to include that commit, and updates `flake.lock`. When the lock changes, it builds Camellya's closure and evaluates Silverwolf's toplevel, then signs and pushes the lockfile. Silverwolf is only evaluated on this Linux runner. If `ATTIC_TOKEN` is set, Camellya's closure is uploaded to the Attic `desktop` cache before the push; a failed upload prevents the push.

The 04:00 schedule leaves a buffer after the servers' 03:00 UTC upgrade checks, which have up to 15 minutes of jitter and can restart the runner guest. It does not wait for upgrades to finish, so long upgrades can still overlap. Desktop activation remains manual.

## Layout

- `hosts/`: machine-specific hardware, filesystems, persistence, secrets, and applications. Camellya's cache and CPU target are configured here.
- `modules/`: shared Nix settings and OS defaults. The flake exports the NixOS and Darwin modules for reuse.
- `users/carmilla/`: account and Home Manager configuration, plus wallpapers.
- `pkgs/`: the Tibia package; `overlays.nix` adds it and the application overrides.

## Conventions

Use Alejandra and keep bindings near their consumers. Use ordinary `let` bindings for shared values; reserve imports for separate modules. Imports come first; related options stay together. Comments explain workarounds and choices that the code alone does not make clear. Commit subjects use `scope: description`.

## Host notes

- Camellya is configured with a tmpfs root, `/tmp`, and `/var/tmp`. Persistent state is listed in `hosts/camellya/persistence.nix`; `/home` has its own filesystem. Persistence does not provide a backup.
- Its kernel targets Zen 5 explicitly so other machines can build it. To use the stock kernel, replace the override with `pkgs.linuxPackages_7_2`.
- Camellya's user profile precedes the system profile on PATH, so interactive commands prefer uutils. The system profile retains GNU utilities, including commands uutils omits. The development shell includes uutils on both platforms; Silverwolf's user profile does not add them.
- WirePlumber renames the RODECaster nodes to fixed names, so the loopback routing needs no device serial. PipeWire accepts [standard JSON configuration](https://docs.pipewire.org/page_man_pipewire_conf_5.html).
- Wallpaper paths point to the checkout; the tracked images are also present in the flake's store snapshot. Home Manager writes Camellya's MIME and monitor settings as writable copies; rebuilds restore the declared values.
- Camellya reads the private `desktop` cache using the `attic-pull-token` SOPS secret. Its token is rendered into a root-only netrc file. The flake still evaluates without decrypting secrets; cache access and hardware operation need checks on the running host.
- Silverwolf's Homebrew activation updates and upgrades packages and removes undeclared formulae and casks. Review `hosts/silverwolf/default.nix` before switching. These downloads and macOS permissions are outside Nix evaluation.
