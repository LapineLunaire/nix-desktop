# The services a graphical host runs: the smartcard daemon, a KMS console, the OOM killer, the Plasma session and its login manager, and PipeWire.
{...}: {
  services.pcscd.enable = true;

  services.kmscon = {
    enable = true;
    useXkbConfig = true;
    config.hwaccel = true;
    config.font-name = "JetBrainsMono Nerd Font";
  };

  services.earlyoom = {
    enable = true;
    freeMemThreshold = 2;
    freeSwapThreshold = 2;
  };

  services.displayManager.plasma-login-manager.enable = true;

  services.desktopManager.plasma6.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # A suspend timeout of zero keeps ALSA nodes from going idle, which causes an audible pop on next use.
    wireplumber.extraConfig."99-disable-suspend" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            {"node.name" = "~alsa_input.*";}
            {"node.name" = "~alsa_output.*";}
          ];
          actions.update-props."session.suspend-timeout-seconds" = 0;
        }
      ];
    };
  };
}
