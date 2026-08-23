-- Gruvbox Dragon · Hyprland (Lua config, Hyprland >= 0.55)
--
-- Entry point only: each module below runs in its own scope, so a runtime
-- error in one file cannot take the others down. Order matters — theme and
-- apps are read by later modules via require(), which caches.
--
--   lua/theme.lua      design tokens + active dark/light variant
--   lua/apps.lua       default applications and script paths
--   lua/env.lua        environment variables (set before clients start)
--   lua/monitors.lua   monitor layout (override per-machine in lua/local.lua)
--   lua/options.lua    general / decoration / input / layout options
--   lua/animations.lua curves and animation tree (fast, KDE-like feel)
--   lua/rules.lua      window / layer / workspace rules
--   lua/applets.lua    KDE-style dropdown popups (close on focus loss)
--   lua/binds.lua      keybindings (vim-flavoured, KDE muscle memory)
--   lua/autostart.lua  session services (bar, notifications, portal env)
--
-- Per-machine overrides live in lua/local.lua (gitignored); start from
-- lua/local.lua.example. It loads last so it can override anything.

require("lua/theme")
require("lua/apps")
require("lua/env")
require("lua/monitors")
require("lua/options")
require("lua/animations")
require("lua/rules")
require("lua/applets")
require("lua/binds")
require("lua/autostart")

pcall(require, "lua/local")
