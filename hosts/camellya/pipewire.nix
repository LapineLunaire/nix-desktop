{config, ...}: {
  services.pipewire.wireplumber.extraConfig = {
    "50-rodecaster"."monitor.alsa.rules" = [
      {
        matches = [
          {
            "device.vendor.id" = "0x19f7";
            "device.product.id" = "0x0079";
          }
        ];
        actions."update-props"."device.profile" = "pro-audio";
      }
      {
        matches = [{"node.name" = "~alsa_output\\.usb-R__DE_RODECaster_Duo_.*\\.pro-output-1";}];
        # Hide the raw output from apps; the virtual sinks still target it.
        actions."update-props"."media.class" = "Audio/Sink/Internal";
      }
    ];
    "51-fiio-k11"."monitor.alsa.rules" = [
      {
        matches = [{"device.name" = "alsa_card.usb-FIIO_FiiO_K11-01";}];
        actions."update-props"."device.profile" = "pro-audio";
      }
      {
        matches = [{"node.name" = "alsa_output.usb-FIIO_FiiO_K11-01.pro-output-0";}];
        # Only the RODECaster main-mix loopback should drive the K11.
        actions."update-props"."media.class" = "Audio/Sink/Internal";
      }
    ];
  };

  # Routing adapted from parzival-space/rodecaster-pro-2-virtual-devices-pipewire.
  sops.templates."rodecaster-duo.conf" = {
    owner = "carmilla";
    mode = "0400";
    content = let
      serial = config.sops.placeholder."rodecaster-duo-serial";
      multichannelOutput = "alsa_output.usb-R__DE_RODECaster_Duo_${serial}.pro-output-1";
    in
      builtins.toJSON {
        "context.modules" =
          (map (sink: {
              name = "libpipewire-module-loopback";
              args = {
                "node.name" = "virtual_output.usb-R__DE_RODECaster_Duo_${serial}.${sink.suffix}";
                "node.description" = "RODECaster Duo ${sink.description}";
                "audio.position" = ["FL" "FR"];
                "capture.props"."media.class" = "Audio/Sink";
                "playback.props" = {
                  "target.object" = multichannelOutput;
                  "stream.dont-remix" = true;
                  "audio.position" = sink.channels;
                };
              };
            }) [
              {
                suffix = "main";
                description = "System";
                channels = ["AUX0" "AUX1"];
              }
              {
                suffix = "game";
                description = "Game";
                channels = ["AUX2" "AUX3"];
              }
              {
                suffix = "music";
                description = "Music";
                channels = ["AUX4" "AUX5"];
              }
              {
                suffix = "a";
                description = "Virtual A";
                channels = ["AUX6" "AUX7"];
              }
              {
                suffix = "b";
                description = "Virtual B";
                channels = ["AUX8" "AUX9"];
              }
            ])
          ++ [
            {
              name = "libpipewire-module-loopback";
              args = {
                "node.name" = "loopback.input-to-fiio";
                "node.description" = "RODECaster Main Mix to FiiO K11";
                "audio.position" = ["FL" "FR"];
                "capture.props" = {
                  "target.object" = "alsa_input.usb-R__DE_RODECaster_Duo_${serial}.pro-input-1";
                  "stream.dont-remix" = true;
                  "audio.position" = ["AUX0" "AUX1"];
                };
                "playback.props" = {
                  "target.object" = "alsa_output.usb-FIIO_FiiO_K11-01.pro-output-0";
                  "stream.dont-remix" = true;
                  "audio.position" = ["AUX0" "AUX1"];
                };
              };
            }
          ];

        "node.rules" =
          map (device: {
            matches = [{"node.name" = device.node;}];
            actions.update-props = {
              "node.description" = "RODECaster Duo ${device.description}";
              "node.nick" = "RODECaster Duo ${device.description}";
            };
          }) [
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
      };
  };

  home-manager.users.carmilla = {
    config,
    osConfig,
    ...
  }: {
    xdg.configFile."pipewire/pipewire.conf.d/51-rodecaster-duo.conf".source =
      config.lib.file.mkOutOfStoreSymlink osConfig.sops.templates."rodecaster-duo.conf".path;
  };
}
