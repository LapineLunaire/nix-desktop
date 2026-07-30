# RODECaster Duo routing: one virtual sink per mixer channel looped into the multichannel output, the physical node renames, and the FiiO K11 the main mix feeds.
{
  config,
  lib,
  pkgs,
  ...
}: let
  serial = config.sops.placeholder."rodecaster-duo-serial";
  multichannelOutput = "alsa_output.usb-R__DE_RODECaster_Duo_${serial}.pro-output-1";

  # One virtual playback device per RODECaster mixer channel, each a loopback feeding its own AUX pair of the multichannel output.
  virtualSinks = [
    {
      suffix = "main";
      description = "System";
      aux = "AUX0 AUX1";
    }
    {
      suffix = "game";
      description = "Game";
      aux = "AUX2 AUX3";
    }
    {
      suffix = "music";
      description = "Music";
      aux = "AUX4 AUX5";
    }
    {
      suffix = "a";
      description = "Virtual A";
      aux = "AUX6 AUX7";
    }
    {
      suffix = "b";
      description = "Virtual B";
      aux = "AUX8 AUX9";
    }
  ];

  loopbackModules =
    lib.concatMapStrings (sink: ''
      # ${sink.description}
      {   name = libpipewire-module-loopback
          args = {
              node.name = "virtual_output.usb-R__DE_RODECaster_Duo_${serial}.${sink.suffix}"
              node.description = "RODECaster Duo ${sink.description}"
              audio.position = [ FL FR ]

              capture.props = { media.class = "Audio/Sink" }

              playback.props = {
                  target.object = "${multichannelOutput}"
                  stream.dont-remix = true
                  audio.position = [ ${sink.aux} ]
              }
          }
      },

    '')
    virtualSinks;

  # The physical RODECaster nodes, renamed after the mixer channel each carries.
  deviceRenames = [
    {
      node = multichannelOutput;
      description = "Multi-Channel";
    }
    {
      node = "alsa_output.usb-R__DE_RODECaster_Duo_${serial}.pro-output-0";
      description = "Chat";
    }
    {
      node = "alsa_input.usb-R__DE_RODECaster_Duo_${serial}.pro-input-0";
      description = "Chat";
    }
    {
      node = "alsa_input.usb-R__DE_RODECaster_Duo_${serial}.pro-input-1";
      description = "Main Mix";
    }
  ];

  nodeRules =
    lib.concatMapStrings (dev: ''
      {
          matches = [ { node.name = "${dev.node}" } ]
          actions = {
              update-props = {
                  node.description = "RODECaster Duo ${dev.description}"
                  node.nick = "RODECaster Duo ${dev.description}"
              }
          }
      },

    '')
    deviceRenames;
in {
  services.pipewire.wireplumber.extraConfig."50-rodecaster"."monitor.alsa.rules" = [
    {
      matches = [
        {
          "device.vendor.id" = "0x19f7";
          "device.product.id" = "0x0079";
        }
      ];
      actions."update-props"."device.profile" = "pro-audio";
    }
    # pulseaudio clients only list nodes whose media.class is exactly Audio/Sink or Audio/Source, while wireplumber still links the /Internal variants to streams that name them in target.object, so the multichannel output keeps feeding the virtual sinks without being selectable as a playback device by applications.
    # pro-input-1 is left a plain Audio/Source: it carries the main mix, which OBS captures directly.
    {
      matches = [{"node.name" = "~alsa_output\\.usb-R__DE_RODECaster_Duo_.*\\.pro-output-1";}];
      actions."update-props"."media.class" = "Audio/Sink/Internal";
    }
  ];

  # RODECaster Duo virtual input/output devices, from parzival-space/rodecaster-pro-2-virtual-devices-pipewire (rodecaster-duo-1.7.3), with the serial templated in from the rodecaster-duo-serial secret.
  sops.templates."rodecaster-duo.conf".mode = "0444";
  sops.templates."rodecaster-duo.conf".content = ''
    context.modules = [
        # Audio sinks / output devices

    ${loopbackModules}
        # RODECaster Input to FiiO K11
        {
            name = libpipewire-module-loopback
            args = {
                node.name = "loopback.input-to-fiio"
                node.description = "RODECaster Main Mix to FiiO K11"
                audio.position = [ FL FR ]

                capture.props = {
                    target.object = "alsa_input.usb-R__DE_RODECaster_Duo_${serial}.pro-input-1"
                    stream.dont-remix = true
                    audio.position = [ AUX0 AUX1 ]
                }

                playback.props = {
                    target.object = "alsa_output.usb-FIIO_FiiO_K11-01.pro-output-0"
                    stream.dont-remix = true
                    audio.position = [ AUX0 AUX1 ]
                }
            }
        }
    ]

    # Assign correct names to physical devices.
    node.rules = [
    ${nodeRules}
    ]
  '';

  services.pipewire.configPackages = [
    (pkgs.runCommand "rodecaster-duo-pipewire-config" {} ''
      mkdir -p $out/share/pipewire/pipewire.conf.d
      ln -s ${config.sops.templates."rodecaster-duo.conf".path} $out/share/pipewire/pipewire.conf.d/51-rodecaster-duo.conf
    '')
  ];

  # Force the pro-audio profile for the FiiO K11 USB DAC so it passes through its native 32-bit format for bit-perfect output.
  services.pipewire.wireplumber.extraConfig."51-fiio-k11"."monitor.alsa.rules" = [
    {
      matches = [{"device.name" = "alsa_card.usb-FIIO_FiiO_K11-01";}];
      actions."update-props"."device.profile" = "pro-audio";
    }
    # The K11 is driven only by the RODECaster main mix loopback, so its output node is internal rather than a sink apps can play to directly.
    {
      matches = [{"node.name" = "alsa_output.usb-FIIO_FiiO_K11-01.pro-output-0";}];
      actions."update-props"."media.class" = "Audio/Sink/Internal";
    }
  ];
}
