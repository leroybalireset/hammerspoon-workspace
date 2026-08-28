-- ============================================================
-- LAYOUT PRESETS
--
-- Each preset defines which app goes in which slot (1–5).
-- Slots are defined in init.lua:
--
--   1 = LG Monitor — left 2/3
--   2 = LG Monitor — right 1/3
--   3 = Mi Monitor — left 1/3
--   4 = Mi Monitor — center 1/3
--   5 = Mi Monitor — right 1/3
--
-- To edit: change the appName values below, then reload
-- Hammerspoon (menubar → Reload Config).
--
-- Set a slot to nil to leave it empty.
-- ============================================================

local M = {}

M.presets = {

    {
        name = "Daily",
        slots = {
            [1] = "ChatGPT",
            [2] = "Spotify",
            [3] = "Claude",
            [4] = "Terminal",
            [5] = "Microsoft Outlook",
        }
    },

    {
        name = "Focus",
        slots = {
            [1] = "Claude",
            [2] = "Terminal",
            [3] = nil,
            [4] = nil,
            [5] = nil,
        }
    },

    {
        name = "Meetings",
        slots = {
            [1] = "zoom.us",
            [2] = "Microsoft Outlook",
            [3] = "Safari",
            [4] = "Slack",
            [5] = nil,
        }
    },

}

return M
