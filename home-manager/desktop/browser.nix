{ config, lib, ... }:

# Browser launch flags — session-independent, so this is deliberately not
# part of the Hyprland or KDE module.
#
# The flags files are an Arch convention: /usr/bin/chromium is a small
# launcher that prepends ~/.config/chromium-flags.conf to the real
# binary's argv (blank lines and # comments stripped); Arch's electron
# wrappers do the same with electron-flags.conf.
#
# The load-bearing flag is --password-store. Chromium derives its
# cookie/password encryption key from whatever desktop it detects: KDE
# gets KWallet, an unrecognised desktop gets `basic` — a hardcoded key.
# XDG_CURRENT_DESKTOP=Hyprland is unrecognised, so the Hyprland session
# could not decrypt anything the KDE session had written and silently
# discarded it, one profile at a time. Pinning the store keeps both
# sessions on the same wallet. Its companion is the Secret portal
# override in xdg-desktop-portal/hyprland-portals.conf (linked by
# ./hyprland.nix) — Chromium reaches the wallet by either route and both
# now behave identically in both sessions.

let
  dotfiles = "${config.home.homeDirectory}/git/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  # out-of-store so a flag edit takes effect on the next browser launch,
  # with no home-manager switch
  xdg.configFile = {
    "chromium-flags.conf".source = link "chromium-flags.conf";
    "electron-flags.conf".source = link "electron-flags.conf";
  };
}
