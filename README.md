# nix-desktop

NixOS and nix-darwin configuration for my desktop and MacBook.

| Host | Platform | Checkout |
|------|----------|----------|
| camellya | x86_64-linux | `/persist/nix-config` |
| silverwolf | aarch64-darwin | `~/projects/nix-config` |

## Quick start

Run from the host's checkout:

```sh
nh os switch .      # camellya
nh darwin switch .  # silverwolf
```

For a new machine or a reinstall, see [installation and recovery](docs/install.md).

## Edit and check

```sh
nix develop
alejandra .
nix flake check --all-systems --no-build --no-write-lock-file --option allow-import-from-derivation false
nix build '.#tibia'  # x86_64-linux only
```

- The shell provides Alejandra, nixd, and the SOPS tools. `direnv allow` loads it automatically.
- Stage new files with `git add` before checking or switching; Git-backed flakes omit untracked files.
- Entering the shell enables the pre-commit hook for this clone, which checks staged Nix files. Without Alejandra, the hook warns and skips the check.
- With `--all-systems`, flake checks evaluate both hosts, including assertions. They do not decrypt secrets or test cache access, Homebrew, or hardware, and builds and activation need the matching platform.
- The [validation workflow](.forgejo/workflows/validate.yml) checks formatting and evaluates both hosts on pushes to main, on pull requests, and on manual dispatch.

On installed Camellya, the `sops` shell alias derives the age identity from the root-owned SSH host key through doas, so `sops hosts/camellya/secrets.yaml` decrypts with that key. See the [key setup](docs/install.md#4-ssh-host-key-and-secrets) before replacing that identity.

Use Alejandra, keep related options and bindings together, put imports first, and explain workarounds in comments. Commit subjects use `scope: description`.

## Automated updates

The [update workflow](.forgejo/workflows/flake-update.yml) runs on the shared `nixos` runner from `nix-server`, daily at 03:30 UTC and on manual dispatch. [Forgejo schedules default to UTC](https://forgejo.org/docs/v15.0/user/actions/reference/#onschedule).

Forgejo queues updates per branch using its [best-effort concurrency control](https://forgejo.org/docs/v15.0/user/actions/reference/#concurrency). Each job checks out the latest branch so queued runs include earlier update commits.

1. The `tibia` job refreshes Tibia's download hash, then builds, signs, and pushes any change.
2. After it succeeds, the `update` job checks out the branch again and updates `flake.lock`.
3. When the lock changes, the job evaluates both hosts, builds Camellya, then signs and pushes the lockfile.

With `ATTIC_TOKEN` set, the workflow uploads Camellya's system closure to the `desktop` Attic cache before pushing, and an upload failure blocks the push. Camellya's [cache module](hosts/camellya/binary-cache.nix) reads its pull token from SOPS.

The schedule follows the server update workflow and the server upgrades. The CI store reset and the server upgrades can interrupt manual runs, and a Sparkle upgrade still running at 03:30 can restart the runner during the scheduled run. Desktop activation stays manual.

## Where to change things

- [`hosts/`](hosts/): hardware, filesystems, persistence, secrets, and host applications.
- [`modules/`](modules/): shared OS defaults and the exported NixOS and Darwin modules.
- [`users/carmilla/`](users/carmilla/): account, Home Manager, and wallpapers.
- [`pkgs/`](pkgs/) and [`overlays.nix`](overlays.nix): Tibia and application overrides.

## Before switching

On Camellya, root, `/tmp`, and `/var/tmp` are tmpfs, and `/home` is its own persistent volume. Check the [persisted state](hosts/camellya/persistence.nix) and keep backups. Home Manager installs the display layout and default applications as writable files. Each boot, and each switch that changes the Home Manager generation, restores the declared values. The [kernel](hosts/camellya/default.nix) targets Zen 5. For the stock kernel, replace the `boot.kernelPackages` override with `pkgs.linuxPackages_7_2`.

On Silverwolf, activation updates and upgrades Homebrew packages and removes undeclared formulae and casks. Review the [package list](hosts/silverwolf/default.nix) first.
