# camellya's monitor layout, written to KWin's output config for both the login manager's greeter and carmilla's session so the two arrangements match.
{pkgs, ...}: let
  # Fields both panels share: 4K at 160Hz, 1.25x scale, HDR with a wide gamut.
  panel = {
    abmLevel = 0;
    allowDdcCi = true;
    allowSdrSoftwareBrightness = true;
    autoBrightnessCurve = [0 0 0 0 0 0 0 0 0 0 0];
    autoRotation = "InTabletMode";
    automaticBrightness = false;
    brightness = 1;
    colorPowerTradeoff = "PreferAccuracy";
    customModes = [];
    detectedDdcCi = false;
    edrPolicy = "always";
    hdrColorProfileSource = "EDID";
    hdrIccProfilePath = "";
    highDynamicRange = true;
    iccProfilePath = "";
    maxBitsPerColor = 0;
    mode = {
      flags = 0;
      height = 2160;
      refreshRate = 160000;
      width = 3840;
    };
    overscan = 0;
    rgbRange = "Automatic";
    scale = 1.25;
    # SDR white lands at the same nit level on both panels, so a window looks unchanged when it moves between them.
    sdrBrightness = 486;
    sdrGamutWideness = 1;
    sharpness = 0;
    vrrPolicy = "Automatic";
    wideColorGamut = true;
  };

  # Landscape, and the output the greeter and the panels belong on.
  dp3 =
    panel
    // {
      colorProfileSource = "sRGB";
      connectorName = "DP-3";
      edidHash = "d1af945b1652fada5e66f1255a067bbf";
      edidIdentifier = "SKG 10100 0 26 2025 0";
      maxPeakBrightnessOverride = 1405;
      transform = "Normal";
    };

  # Turned a quarter clockwise, giving 1728x3072 of logical space.
  dp2 =
    panel
    // {
      colorProfileSource = "EDID";
      connectorName = "DP-2";
      edidHash = "713337e9a897a5cf035b654c2fd45fb5";
      edidIdentifier = "SKG 10104 0 30 2025 0";
      transform = "Rotated90";
    };

  # Positions are in logical pixels and index into the outputs list. Priority 1 is the primary output.
  setups = [
    {
      lidClosed = false;
      outputs = [
        {
          enabled = true;
          outputIndex = 0;
          position = {
            x = 0;
            y = 0;
          };
          priority = 1;
          replicationSource = "";
        }
      ];
    }
    {
      lidClosed = false;
      outputs = [
        {
          enabled = true;
          outputIndex = 1;
          position = {
            x = 3072;
            y = 0;
          };
          priority = 2;
          replicationSource = "";
        }
        # Dropped 550px so the two panels line up at eye level rather than at their top edges.
        {
          enabled = true;
          outputIndex = 0;
          position = {
            x = 0;
            y = 550;
          };
          priority = 1;
          replicationSource = "";
        }
      ];
    }
    {
      lidClosed = false;
      outputs = [
        {
          enabled = true;
          outputIndex = 1;
          position = {
            x = 0;
            y = 0;
          };
          priority = 1;
          replicationSource = "";
        }
      ];
    }
  ];

  kwinOutputConfig = pkgs.writeText "kwinoutputconfig.json" (builtins.toJSON [
    {
      data = [dp3 dp2];
      name = "outputs";
    }
    {
      data = setups;
      name = "setups";
    }
  ]);
in {
  # The greeter runs kwin_wayland as the plasmalogin user, which reads this file out of that user's home.
  systemd.tmpfiles.settings."10-plasma-login-displays" = {
    "/var/lib/plasmalogin/.config".d = {
      mode = "0750";
      user = "plasmalogin";
      group = "plasmalogin";
    };
    "/var/lib/plasmalogin/.config/kwinoutputconfig.json"."L+".argument = "${kwinOutputConfig}";
  };

  # A writable copy, so the display KCM still saves; each rebuild resets it to what this file declares.
  home-manager.users.carmilla = {lib, ...}: {
    home.activation.kwinOutputConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run install -Dm644 ${kwinOutputConfig} "$HOME/.config/kwinoutputconfig.json"
    '';
  };
}
