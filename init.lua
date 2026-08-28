-- ============================================================
-- 2-MONITOR WORKSPACE MANAGER
--
-- WINDOWS KEYBOARD SHORTCUTS
--
-- Ctrl + Alt + 1 = Location 1
-- Ctrl + Alt + 2 = Location 2
-- Ctrl + Alt + 3 = Location 3
-- Ctrl + Alt + 4 = Location 4
-- Ctrl + Alt + 5 = Location 5
-- Ctrl + Alt + 6 = Left 50% of current monitor
-- Ctrl + Alt + 7 = Right 50% of current monitor
-- Ctrl + Alt + 8 = Left 2/3 of current monitor
--
-- Ctrl + Alt + A = Tile all windows in a grid on LG Monitor
--
-- Ctrl + Alt + L = Full screen on LG Monitor (left)
-- Ctrl + Alt + R = Full screen on Mi Monitor (right)
--
-- Ctrl + Alt + M = Minimize focused window
-- Ctrl + Alt + N = Focus next window
--
-- Ctrl + Alt + S = Swap two locations
-- Ctrl + Alt + D = Open Layout Picker menu
--
-- LAYOUT PICKER (menubar ⊞ or Ctrl+Alt+D)
-- Presets defined in ~/.hammerspoon/config.lua
-- "Edit Layouts..." opens config.lua in TextEdit
-- "Reload Config" reloads Hammerspoon
-- ============================================================


hs.allowAppleScript(true)

local winTags     = require("window_tags")
local layoutPal   = require("layout_palette")
layoutPal.init(winTags)

--------------------------------------------------------------
-- FIND MONITORS
--------------------------------------------------------------

local function getLG()
    return hs.screen.find("LG QHD")
end

local function getMi()
    return hs.screen.find("Mi Monitor")
end


--------------------------------------------------------------
-- DEFINE THE 5 LOCATIONS
--------------------------------------------------------------

local function getSlots()

    local lg = getLG()
    local mi = getMi()

    if not lg or not mi then
        hs.alert.show("Both monitors not found")
        return nil
    end

    local L = lg:fullFrame()
    local M = mi:fullFrame()

    return {
        -- LG: left 2/3
        [1] = { x = L.x,                 y = L.y, w = math.floor(L.w * 2/3), h = L.h },
        -- LG: right 1/3
        [2] = { x = L.x + math.floor(L.w * 2/3), y = L.y, w = L.w - math.floor(L.w * 2/3), h = L.h },
        -- Mi: left 1/3
        [3] = { x = M.x,                 y = M.y, w = math.floor(M.w * 1/3), h = M.h },
        -- Mi: center 1/3
        [4] = { x = M.x + math.floor(M.w * 1/3), y = M.y, w = math.floor(M.w * 1/3), h = M.h },
        -- Mi: right 1/3
        [5] = { x = M.x + math.floor(M.w * 2/3), y = M.y, w = M.w - math.floor(M.w * 2/3), h = M.h },
    }
end


--------------------------------------------------------------
-- MOVE ACTIVE WINDOW TO A LOCATION
--------------------------------------------------------------

local function moveToSlot(slotNumber)

    local win = hs.window.focusedWindow()

    if not win then
        hs.alert.show("No active window")
        return
    end

    local slots = getSlots()
    if not slots then return end

    win:setFrame(slots[slotNumber], 0)

    hs.alert.show("Location " .. slotNumber)
end


--------------------------------------------------------------
-- LOCATION SHORTCUTS
--
-- Windows Keyboard:
--
-- Ctrl + Alt + 1
-- Ctrl + Alt + 2
-- Ctrl + Alt + 3
-- Ctrl + Alt + 4
-- Ctrl + Alt + 5
--------------------------------------------------------------

for i = 1,5 do

    hs.hotkey.bind(
        {"ctrl","alt"},
        tostring(i),
        function()
            moveToSlot(i)
        end
    )

end


--------------------------------------------------------------
-- RELATIVE SPLITS ON CURRENT MONITOR
--
-- Ctrl + Alt + 6 = Left 50%
-- Ctrl + Alt + 7 = Right 50%
-- Ctrl + Alt + 8 = Left 2/3
--------------------------------------------------------------

local relativeSplits = {
    [6] = function(f) return { x = f.x,               y = f.y, w = f.w * (1/2), h = f.h } end,
    [7] = function(f) return { x = f.x + f.w * (1/2), y = f.y, w = f.w * (1/2), h = f.h } end,
    [8] = function(f) return { x = f.x,               y = f.y, w = f.w * (2/3), h = f.h } end,
}

for i, splitFn in pairs(relativeSplits) do
    hs.hotkey.bind(
        {"ctrl","alt"},
        tostring(i),
        function()
            local win = hs.window.focusedWindow()
            if not win then
                hs.alert.show("No active window")
                return
            end
            local screen = win:screen()
            if not screen then
                hs.alert.show("No screen found")
                return
            end
            local f = screen:frame()
            win:setFrame(splitFn(f), 0)
            hs.alert.show("Location " .. i)
        end
    )
end


--------------------------------------------------------------
-- FOCUS NEXT WINDOW
--
-- Ctrl + Alt + N
--------------------------------------------------------------

hs.hotkey.bind(
    {"ctrl","alt"},
    "N",
    function()
        local current = hs.window.focusedWindow()
        if not current then
            hs.alert.show("No active window")
            return
        end

        local wins = {}
        for _, win in ipairs(hs.window.visibleWindows()) do
            if win:isStandard() then
                table.insert(wins, win)
            end
        end

        if #wins < 2 then return end

        local currentIndex = 1
        for i, win in ipairs(wins) do
            if win == current then
                currentIndex = i
                break
            end
        end

        local nextIndex = (currentIndex % #wins) + 1
        local next = wins[nextIndex]

        local currentFrame = current:frame()
        local nextFrame = next:frame()

        current:setFrame(nextFrame, 0)
        next:setFrame(currentFrame, 0)

        current:focus()
    end
)


--------------------------------------------------------------
-- MINIMIZE FOCUSED WINDOW
--
-- Ctrl + Alt + M
--------------------------------------------------------------

hs.hotkey.bind(
    {"ctrl","alt"},
    "M",
    function()
        local win = hs.window.focusedWindow()
        if not win then
            hs.alert.show("No active window")
            return
        end
        win:minimize()
    end
)


--------------------------------------------------------------
-- TILE ALL WINDOWS ON LG MONITOR
--
-- Ctrl + Alt + A
--------------------------------------------------------------

hs.hotkey.bind(
    {"ctrl","alt"},
    "A",
    function()
        local lg = getLG()
        if not lg then
            hs.alert.show("LG monitor not found")
            return
        end

        local wins = {}
        for _, win in ipairs(hs.window.visibleWindows()) do
            if win:isStandard() then
                table.insert(wins, win)
            end
        end

        local count = #wins
        if count == 0 then
            hs.alert.show("No windows open")
            return
        end

        local f = lg:frame()

        -- Find the largest minimum size across all windows
        -- so every window can fit in its cell comfortably.
        local minCellW = 0
        local minCellH = 0

        for _, win in ipairs(wins) do
            local wf = win:frame()
            if wf.w > minCellW then minCellW = wf.w end
            if wf.h > minCellH then minCellH = wf.h end
        end

        -- How many cols/rows fit given the natural window sizes.
        local cols = math.max(1, math.floor(f.w / minCellW))
        local rows = math.max(1, math.ceil(count / cols))

        -- Cell size fills the monitor evenly across those cols/rows.
        local cellW = math.floor(f.w / cols)
        local cellH = math.floor(f.h / rows)

        for i, win in ipairs(wins) do
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)
            win:moveToScreen(lg, false, true, 0)
            win:setFrame({
                x = f.x + col * cellW,
                y = f.y + row * cellH,
                w = cellW,
                h = cellH
            }, 0)
        end

        hs.alert.show("All Windows — " .. cols .. "×" .. rows .. " Grid")
    end
)


--------------------------------------------------------------
-- FULL SCREEN ON A MONITOR
--
-- Ctrl + Alt + L = LG Monitor (left)
-- Ctrl + Alt + R = Mi Monitor (right)
--------------------------------------------------------------

hs.hotkey.bind(
    {"ctrl","alt"},
    "L",
    function()
        local win = hs.window.focusedWindow()
        if not win then
            hs.alert.show("No active window")
            return
        end
        local lg = getLG()
        if not lg then
            hs.alert.show("LG monitor not found")
            return
        end
        win:setFrame(lg:frame(), 0)
        hs.alert.show("LG — Full Screen")
    end
)

hs.hotkey.bind(
    {"ctrl","alt"},
    "R",
    function()
        local win = hs.window.focusedWindow()
        if not win then
            hs.alert.show("No active window")
            return
        end
        local mi = getMi()
        if not mi then
            hs.alert.show("Mi monitor not found")
            return
        end
        win:setFrame(mi:frame(), 0)
        hs.alert.show("Mi — Full Screen")
    end
)


--------------------------------------------------------------
-- FIND WINDOW CURRENTLY OCCUPYING A LOCATION
--------------------------------------------------------------

local function windowInSlot(slotNumber)

    local slots = getSlots()
    if not slots then return nil end

    local target = slots[slotNumber]

    local targetCenterX = target.x + target.w / 2
    local targetCenterY = target.y + target.h / 2

    local bestWindow = nil
    local bestDistance = math.huge

    for _, win in ipairs(hs.window.visibleWindows()) do

        if win:isStandard() then

            local f = win:frame()

            local centerX = f.x + f.w / 2
            local centerY = f.y + f.h / 2

            local distance =
                math.abs(centerX - targetCenterX) +
                math.abs(centerY - targetCenterY)

            if distance < bestDistance then
                bestDistance = distance
                bestWindow = win
            end
        end
    end

    return bestWindow
end


--------------------------------------------------------------
-- SWAP TWO LOCATIONS
--------------------------------------------------------------

local function swapSlots(a, b)

    local slots = getSlots()
    if not slots then return end

    local winA = windowInSlot(a)
    local winB = windowInSlot(b)

    if not winA or not winB then
        hs.alert.show("Window missing")
        return
    end

    -- Move each window to the other's location.
    winA:setFrame(slots[b], 0)
    winB:setFrame(slots[a], 0)

    hs.alert.show(
        "Swapped " .. a .. " ↔ " .. b
    )
end


--------------------------------------------------------------
-- SWAP MODE
--
-- Ctrl + Alt + S
--
-- Example:
--
-- Ctrl + Alt + S
-- Enter 5
-- Enter 1
--
-- Location 5 and Location 1 exchange windows.
--------------------------------------------------------------

hs.hotkey.bind(
    {"ctrl","alt"},
    "S",
    function()

        local firstButton, first =
            hs.dialog.textPrompt(
                "Swap Windows",
                "First location (1-5):",
                "",
                "Next",
                "Cancel"
            )

        if firstButton ~= "Next" then
            return
        end

        local a = tonumber(first)

        if not a or a < 1 or a > 5 then
            hs.alert.show("Use locations 1-5")
            return
        end

        local secondButton, second =
            hs.dialog.textPrompt(
                "Swap Windows",
                "Swap Location " .. a .. " with:",
                "",
                "Swap",
                "Cancel"
            )

        if secondButton ~= "Swap" then
            return
        end

        local b = tonumber(second)

        if not b or b < 1 or b > 5 then
            hs.alert.show("Use locations 1-5")
            return
        end

        if a == b then
            hs.alert.show("Choose two different locations")
            return
        end

        swapSlots(a, b)
    end
)


-- ============================================================
-- AI LAYOUT
-- ============================================================

function applyAILayout()
    local lg = getLG()
    local mi = getMi()
    if not lg or not mi then
        hs.alert.show("Both monitors not found")
        return
    end

    local S = {
        chrome   = { x = -2560, y = 0, w = 1280, h = 1440 },
        chatgpt  = { x = -1280, y = 0, w =  640, h = 1440 },
        telegram = { x =  -640, y = 0, w =  640, h = 1440 },
        slack    = { x =    0,  y = 0, w =  860, h = 1440 },
        kiro     = { x =  860,  y = 0, w =  860, h = 1440 },
        term1    = { x = 1720,  y = 0, w =  860, h = 1440 },
        term2    = { x = 2580,  y = 0, w =  860, h = 1440 },
    }

    local function snapWin(win, frame)
        if not win then return end
        if win:isMinimized() then win:unminimize() end
        win:setFrame(hs.geometry.rect(frame.x, frame.y, frame.w, frame.h), 0)
    end

    local function getWinByBundle(bundleID)
        local app = hs.application.get(bundleID)
        if not app then return nil end
        for _, w in ipairs(app:allWindows()) do
            if w:isStandard() then return w end
        end
        return nil
    end

    -- Launch all apps
    hs.application.launchOrFocusByBundleID("com.google.Chrome")
    hs.application.launchOrFocusByBundleID("com.openai.codex")
    hs.application.launchOrFocusByBundleID("ru.keepcoder.Telegram")
    hs.application.launchOrFocusByBundleID("com.tinyspeck.slackmacgap")
    hs.application.launchOrFocusByBundleID("dev.kiro.desktop")
    hs.application.launchOrFocusByBundleID("com.apple.Terminal")

    -- Ensure 2 Terminal windows
    hs.timer.doAfter(2, function()
        local t = hs.application.get("com.apple.Terminal")
        if t then
            local wins = {}
            for _, w in ipairs(t:allWindows()) do
                if w:isStandard() then table.insert(wins, w) end
            end
            if #wins < 2 then
                hs.eventtap.keyStroke({"cmd"}, "n", 0, t)
            end
        end
    end)

    -- Place all windows after apps have settled
    hs.timer.doAfter(3.5, function()
        snapWin(getWinByBundle("com.google.Chrome"),        S.chrome)
        snapWin(getWinByBundle("com.openai.codex"),         S.chatgpt)
        snapWin(getWinByBundle("ru.keepcoder.Telegram"),    S.telegram)
        snapWin(getWinByBundle("com.tinyspeck.slackmacgap"), S.slack)
        snapWin(getWinByBundle("dev.kiro.desktop"),          S.kiro)

        -- Terminal: sort windows left-to-right by current x position, assign slots
        local t = hs.application.get("com.apple.Terminal")
        if t then
            local wins = {}
            for _, w in ipairs(t:allWindows()) do
                if w:isStandard() then table.insert(wins, w) end
            end
            table.sort(wins, function(a, b) return a:frame().x < b:frame().x end)
            snapWin(wins[1], S.term1)
            snapWin(wins[2], S.term2)
        end

        hs.alert.show("AI Layout Ready")
    end)

    hs.alert.show("AI Layout...")
end

hs.hotkey.bind({}, "f1", applyAILayout)


-- ============================================================
-- LAYOUT PRESETS + MENUBAR PICKER
-- ============================================================

local ok, config = pcall(require, "config")
if not ok then
    hs.alert.show("Layout config error: " .. tostring(config))
    config = { presets = {} }
end


--------------------------------------------------------------
-- OPEN APP AND PLACE IT IN A SLOT
--------------------------------------------------------------

local function placeAppInSlot(appName, slotNumber)

    local slots = getSlots()
    if not slots then return end

    local function moveWin(win)
        if win:isMinimized() then win:unminimize() end
        win:setFrame(slots[slotNumber], 0)
    end

    local app = hs.appfinder.appFromName(appName)

    if app then
        -- App already running — grab its window now
        local win = app:mainWindow()
        if not win then
            for _, w in ipairs(app:allWindows()) do
                if w:isStandard() then win = w; break end
            end
        end
        if win then
            moveWin(win)
            return
        end
    end

    -- App not running (or no window yet) — launch and wait
    hs.application.launchOrFocus(appName)

    local tries = 0
    hs.timer.doEvery(0.25, function(t)
        tries = tries + 1
        local a = hs.appfinder.appFromName(appName)
        local win = a and a:mainWindow()
        if not win and a then
            for _, w in ipairs(a:allWindows()) do
                if w:isStandard() then win = w; break end
            end
        end
        if win then
            t:stop()
            moveWin(win)
        elseif tries > 40 then
            t:stop()
            hs.alert.show("No window for " .. appName)
        end
    end)
end


--------------------------------------------------------------
-- APPLY A NAMED PRESET
--------------------------------------------------------------

local function applyPreset(preset)

    hs.alert.show("Layout: " .. preset.name)

    for slotNumber, appName in pairs(preset.slots) do
        if appName then
            placeAppInSlot(appName, slotNumber)
        end
    end

    hs.timer.doAfter(3, function()
        hs.alert.show(preset.name .. " Ready")
    end)

end


--------------------------------------------------------------
-- TIDY — DISTRIBUTE ALL WINDOWS ACROSS SLOTS 1–5
--------------------------------------------------------------

local function applyTidy(label, tidySlots)
    local wins = {}
    for _, win in ipairs(hs.window.visibleWindows()) do
        if win:isStandard() then
            table.insert(wins, win)
        end
    end
    if #wins == 0 then
        hs.alert.show("No windows to tidy")
        return
    end
    local n = #tidySlots
    for i, win in ipairs(wins) do
        local slot = tidySlots[((i - 1) % n) + 1]
        if win:isMinimized() then win:unminimize() end
        win:setFrame(slot, 0)
    end
    hs.alert.show(label .. " — " .. #wins .. " window" .. (#wins == 1 and "" or "s"))
end

-- Per-monitor even split: each screen divides itself by however many windows are on it.
-- Supports 1–4 windows per screen. Windows are sorted left-to-right before snapping.
local function smartTidy()
    local lg = getLG()
    local mi = getMi()
    if not lg or not mi then hs.alert.show("Both monitors not found"); return end
    local L = lg:fullFrame()
    local M = mi:fullFrame()

    -- Bucket visible windows by which screen they're on
    local lgWins, miWins = {}, {}
    for _, win in ipairs(hs.window.visibleWindows()) do
        if win:isStandard() then
            local sc = win:screen()
            if sc and sc:id() == lg:id() then
                table.insert(lgWins, win)
            elseif sc and sc:id() == mi:id() then
                table.insert(miWins, win)
            end
        end
    end

    if #lgWins == 0 and #miWins == 0 then
        hs.alert.show("No windows to tidy")
        return
    end

    -- Sort each group left-to-right so snap order is predictable
    local function sortLR(wins)
        table.sort(wins, function(a, b) return a:frame().x < b:frame().x end)
    end
    sortLR(lgWins)
    sortLR(miWins)

    -- Build even column slots for a given screen rect and window count
    local function makeSlots(F, n)
        if n == 0 then return {} end
        local slots = {}
        local colW = math.floor(F.w / n)
        for i = 0, n - 1 do
            local x = F.x + i * colW
            local w = (i == n - 1) and (F.w - i * colW) or colW  -- last column absorbs rounding
            table.insert(slots, { x = x, y = F.y, w = w, h = F.h })
        end
        return slots
    end

    local function snapGroup(wins, F)
        local n = math.min(#wins, 8)  -- max 8 columns per screen
        local slots = makeSlots(F, n)
        for i, win in ipairs(wins) do
            local slot = slots[math.min(i, n)]
            if win:isMinimized() then win:unminimize() end
            win:setFrame(hs.geometry.rect(slot.x, slot.y, slot.w, slot.h), 0)
        end
    end

    snapGroup(lgWins, L)
    snapGroup(miWins, M)

    local msg = "Even Split — LG:" .. #lgWins .. "  Mi:" .. #miWins
    hs.alert.show(msg)
end

hs.hotkey.bind({}, "f2", smartTidy)


-- Per-monitor focus split: first window = 2/3, rest share the remaining 1/3 equally.
-- Windows sorted left-to-right before snapping so the largest column is leftmost.
local function focusSplit()
    local lg = getLG()
    local mi = getMi()
    if not lg or not mi then hs.alert.show("Both monitors not found"); return end
    local L = lg:fullFrame()
    local M = mi:fullFrame()

    local lgWins, miWins = {}, {}
    for _, win in ipairs(hs.window.visibleWindows()) do
        if win:isStandard() then
            local sc = win:screen()
            if sc and sc:id() == lg:id() then
                table.insert(lgWins, win)
            elseif sc and sc:id() == mi:id() then
                table.insert(miWins, win)
            end
        end
    end

    if #lgWins == 0 and #miWins == 0 then
        hs.alert.show("No windows to arrange")
        return
    end

    local function sortLR(wins)
        table.sort(wins, function(a, b) return a:frame().x < b:frame().x end)
    end
    sortLR(lgWins)
    sortLR(miWins)

    local function snapFocusSplit(wins, F)
        local n = #wins
        if n == 0 then return end
        if n == 1 then
            -- Single window: give it 2/3
            wins[1]:setFrame(hs.geometry.rect(F.x, F.y, math.floor(F.w * 2/3), F.h), 0)
            return
        end
        -- First window: 2/3
        local mainW = math.floor(F.w * 2/3)
        wins[1]:setFrame(hs.geometry.rect(F.x, F.y, mainW, F.h), 0)
        -- Remaining windows share the 1/3
        local sideW = F.w - mainW
        local sliceW = math.floor(sideW / (n - 1))
        for i = 2, n do
            local x = F.x + mainW + (i - 2) * sliceW
            local w = (i == n) and (F.x + F.w - x) or sliceW  -- last slice absorbs rounding
            wins[i]:setFrame(hs.geometry.rect(x, F.y, w, F.h), 0)
        end
    end

    snapFocusSplit(lgWins, L)
    snapFocusSplit(miWins, M)

    hs.alert.show("Focus Split — LG:" .. #lgWins .. "  Mi:" .. #miWins)
end

hs.hotkey.bind({}, "f3", focusSplit)
hs.hotkey.bind({}, "f4", function() winTags.toggleTagMode() end)
hs.hotkey.bind({}, "f5", function() layoutPal.toggle() end)
hs.hotkey.bind({}, "f6", function() winTags.reset() end)


--------------------------------------------------------------
-- BUILD MENUBAR MENU TABLE
--------------------------------------------------------------

local function buildMenu()

    local items = {}

    -- AI layout (custom geometry, not a slot preset)
    table.insert(items, {
        title = "AI  fn+F1",
        fn    = applyAILayout,
    })
    table.insert(items, { title = "-" })

    for _, preset in ipairs(config.presets) do
        local p = preset
        table.insert(items, {
            title = preset.name,
            fn    = function() applyPreset(p) end,
        })
    end

    table.insert(items, { title = "-" })

    table.insert(items, {
        title = "Even Split  fn+F2",
        fn    = function() smartTidy() end,
    })

    table.insert(items, {
        title = "Focus Split  fn+F3",
        fn    = function() focusSplit() end,
    })

    table.insert(items, { title = "-" })

    table.insert(items, {
        title = "Layout Palette  fn+F5",
        fn    = function() layoutPal.toggle() end,
    })

    table.insert(items, {
        title = "Tag Mode  fn+F4",
        fn    = function() winTags.toggleTagMode() end,
    })

    table.insert(items, {
        title = "Reset Tags  fn+F6",
        fn    = function() winTags.reset() end,
    })

    table.insert(items, { title = "-" })

    table.insert(items, {
        title = "Edit Layouts...",
        fn = function()
            hs.execute("open -a 'TextEdit' ~/.hammerspoon/config.lua")
        end
    })

    table.insert(items, {
        title = "Reload Config",
        fn = function()
            hs.reload()
        end
    })

    return items

end


--------------------------------------------------------------
-- MENUBAR ICON
--------------------------------------------------------------

local layoutMenu = hs.menubar.new()

if layoutMenu then
    layoutMenu:setTitle("[WS]")
    layoutMenu:setMenu(buildMenu)
end


--------------------------------------------------------------
-- Ctrl + Alt + D — OPEN THE LAYOUT PICKER MENU
--------------------------------------------------------------

hs.hotkey.bind(
    {"ctrl","alt"},
    "D",
    function()
        if layoutMenu then
            layoutMenu:popupMenu(hs.mouse.absolutePosition())
        end
    end
)


-- ============================================================
-- CONFIGURATION LOADED
-- ============================================================

hs.alert.show("Workspace Manager Ready")