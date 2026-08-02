# The font set and the fontconfig rules that pick a CJK face per language.
{
  lib,
  pkgs,
  ...
}: let
  cjkFamilies = {
    monospace = "Noto Sans Mono CJK";
    sans-serif = "Noto Sans CJK";
    serif = "Noto Serif CJK";
  };

  # Appended in order: the tagged language, then Han with no tag (fontconfig's own rules land on Korean), then emoji.
  tiers =
    lib.mapAttrsToList (lang: face: {
      inherit lang;
      family = generic: "${cjkFamilies.${generic}} ${face}";
    }) {
      ja = "JP";
      ko = "KR";
      "zh-cn" = "SC";
      "zh-hk" = "HK";
      "zh-tw" = "TC";
    }
    ++ [
      {family = generic: "${cjkFamilies.${generic}} TC";}
      # Appended rather than prepended: ahead of the text faces it colours codepoints that are only incidentally emoji, U+00A9 among them.
      {family = _: "Noto Color Emoji";}
    ];

  # append_last, not append: append inserts after the element the test matched, which orders the tiers backwards.
  rules =
    lib.concatMapStrings (
      tier:
        lib.concatMapStrings (generic: ''
          <match target="pattern">
            ${lib.optionalString (tier ? lang) ''<test name="lang" compare="contains"><string>${tier.lang}</string></test>''}
            <test name="family"><string>${generic}</string></test>
            <edit name="family" mode="append_last" binding="strong"><string>${tier.family generic}</string></edit>
          </match>
        '') (lib.attrNames cjkFamilies)
    )
    tiers;
in {
  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
    ];

    fontconfig = {
      subpixel.rgba = "rgb";

      # Latin only: defaultFonts has no notion of language, so a CJK face here would be pinned across every locale.
      defaultFonts = {
        monospace = ["JetBrainsMono Nerd Font"];
        sansSerif = ["Noto Sans"];
        serif = ["Noto Serif"];
        emoji = ["Noto Color Emoji"];
      };

      # A conf.d file rather than fonts.fontconfig.localConf: localConf is pulled in by a relative include that did not resolve under test, while conf.d is read directly.
      confPackages = [
        (pkgs.writeTextDir "etc/fonts/conf.d/60-cjk-emoji.conf" ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
          <fontconfig>
          ${rules}</fontconfig>
        '')
      ];
    };
  };
}
