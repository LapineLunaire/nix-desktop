# Install Silverwolf

Replace `<repo>` with the repository URL. To recover, restore user data and reapply this configuration.

## Prerequisites

Before the first switch, you need:

- Apple Silicon and macOS 26 or later for the declared [Homebrew `container` formula](https://formulae.brew.sh/formula/container).
- An existing `carmilla` account at `/Users/carmilla`.
- [Homebrew](https://brew.sh/) and [multi-user Nix](https://nix.dev/manual/nix/2.34/installation/installing-binary.html); complete shell setup and check `brew --version` and `nix --version` in a new terminal.
- A Mac App Store sign-in for `masApps`.
- App Management permission for the terminal (**System Settings > Privacy & Security > App Management**), so activation can replace existing applications.

Review `hosts/silverwolf/default.nix` first. Activation updates and upgrades Homebrew packages and removes undeclared formulae and casks. nix-darwin does not install Homebrew; if Homebrew is missing, activation reports an error and skips Homebrew packages without aborting.

## First switch

```sh
mkdir -p ~/projects
git clone <repo> ~/projects/nix-config
cd ~/projects/nix-config
sudo nix --extra-experimental-features 'nix-command flakes' run --inputs-from . nix-darwin#darwin-rebuild \
  -- switch --flake .#silverwolf
```

The first switch uses this checkout's pinned nix-darwin because `nh` is not installed yet. Then create `~/Pictures/Screenshots`.

Restore the [YubiKey SSH and Git signing identity](keys.md#yubikey-ssh-and-git-signing-both-hosts). For routine switches, see the [README quick start](../README.md#quick-start).
