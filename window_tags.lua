-- ============================================================
-- WINDOW TAGGING SYSTEM
--
-- F4            = toggle tag mode (click windows to number them)
-- F4 (hold)     = same
-- In tag mode:  click any window to assign the next number
--               click a tagged window to remove its tag
-- Badges float above each tagged window, update on a timer.
-- Reset clears all tags and badges.
-- ============================================================

local M = {}

-- State
local tags      = {}   -- { [windowID] = tagNumber }
local badges    = {}   -- { [windowID] = hs.canvas }
local tagMode   = false
local clickWatcher = nil
local posTimer  = nil

local BADGE_SIZE   = 36
local BADGE_MARGIN = 28
local FONT_SIZE    = 18
local UPDATE_HZ    = 0.15   -- seconds between position updates

-- ── Helpers ──────────────────────────────────────────────────

local function nextTag()
    local used = {}
    for _, n in pairs(tags) do used[n] = true end
    local i = 1
    while used[i] do i = i + 1 end
    return i
end

local function tagCount()
    local n = 0
    for _ in pairs(tags) do n = n + 1 end
    return n
end

-- ── Badge drawing ─────────────────────────────────────────────

local function badgeColor(n)
    local colors = {
        { r=0.20, g=0.60, b=1.00 },  -- 1 blue
        { r=0.10, g=0.75, b=0.40 },  -- 2 green
        { r=1.00, g=0.40, b=0.10 },  -- 3 orange
        { r=0.80, g=0.15, b=0.80 },  -- 4 purple
        { r=0.90, g=0.15, b=0.25 },  -- 5 red
        { r=0.10, g=0.75, b=0.85 },  -- 6 cyan
        { r=0.95, g=0.75, b=0.05 },  -- 7 yellow
        { r=0.55, g=0.35, b=0.95 },  -- 8 violet
        { r=0.00, g=0.55, b=0.45 },  -- 9 teal
        { r=0.85, g=0.50, b=0.10 },  -- 10 amber
    }
    return colors[((n - 1) % #colors) + 1]
end

local function badgeFrameForWin(win)
    local f = win:frame()
    return {
        x = f.x + BADGE_MARGIN,
        y = f.y + BADGE_MARGIN,
        w = BADGE_SIZE,
        h = BADGE_SIZE,
    }
end

local function makeBadge(win, n)
    local bf = badgeFrameForWin(win)
    local c  = hs.canvas.new(bf)
    local col = badgeColor(n)

    c:appendElements({
        type             = "circle",
        center           = { x = BADGE_SIZE/2, y = BADGE_SIZE/2 },
        radius           = BADGE_SIZE/2 - 1,
        fillColor        = { red=col.r, green=col.g, blue=col.b, alpha=0.92 },
        strokeColor      = { red=1, green=1, blue=1, alpha=0.6 },
        strokeWidth      = 2,
        action           = "strokeAndFill",
    }, {
        type             = "text",
        text             = tostring(n),
        textSize         = FONT_SIZE,
        textFont         = "Helvetica-Bold",
        textColor        = { red=1, green=1, blue=1, alpha=1 },
        frame            = { x=0, y=(BADGE_SIZE - FONT_SIZE*1.1)/2, w=BADGE_SIZE, h=BADGE_SIZE },
        textAlignment    = "center",
    })

    c:level(hs.canvas.windowLevels.floating + 1)
    c:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces +
               hs.canvas.windowBehaviors.stationary)
    c:show()
    return c
end

local function destroyBadge(wid)
    if badges[wid] then
        badges[wid]:hide()
        badges[wid]:delete()
        badges[wid] = nil
    end
end

-- ── Position updater ──────────────────────────────────────────

local function updatePositions()
    for wid, canvas in pairs(badges) do
        local win = hs.window.get(wid)
        if win and not win:isMinimized() then
            local bf = badgeFrameForWin(win)
            canvas:frame(bf)
            canvas:show()
        elseif canvas then
            canvas:hide()  -- minimized: hide badge until restored
        end
    end
end

-- ── Tag / untag ───────────────────────────────────────────────

local function tagWindow(win)
    local wid = win:id()
    if tags[wid] then return end  -- already tagged, ignore (double-click handles removal)
    local n = nextTag()
    tags[wid] = n
    destroyBadge(wid)
    badges[wid] = makeBadge(win, n)
    hs.alert.show("Tagged " .. n)
end

-- ── Click capture ─────────────────────────────────────────────

local lastClickTime = 0
local lastClickWid  = nil

local function startClickCapture()
    clickWatcher = hs.eventtap.new(
        { hs.eventtap.event.types.leftMouseDown },
        function(e)
            local now = hs.timer.secondsSinceEpoch()
            local pos = e:location()

            hs.timer.doAfter(0.08, function()
                -- Find which window was clicked by position
                local hit = nil
                for _, win in ipairs(hs.window.orderedWindows()) do
                    if win:isStandard() and not win:isMinimized() then
                        local f = win:frame()
                        if pos.x >= f.x and pos.x <= f.x + f.w and
                           pos.y >= f.y and pos.y <= f.y + f.h then
                            hit = win
                            break
                        end
                    end
                end
                if not hit then return end

                local wid = hit:id()
                local dt  = now - lastClickTime
                local isDouble = (dt < 0.4) and (lastClickWid == wid)

                if isDouble then
                    -- Double-click: remove tag from this window
                    if tags[wid] then
                        local removed = tags[wid]
                        tags[wid] = nil
                        destroyBadge(wid)
                        -- Resequence remaining
                        local ordered = {}
                        for id, n in pairs(tags) do table.insert(ordered, { id=id, n=n }) end
                        table.sort(ordered, function(a,b) return a.n < b.n end)
                        tags = {}
                        for i, entry in ipairs(ordered) do
                            tags[entry.id] = i
                            destroyBadge(entry.id)
                            local w = hs.window.get(entry.id)
                            if w then badges[entry.id] = makeBadge(w, i) end
                        end
                        hs.alert.show("Tag " .. removed .. " removed")
                    end
                    lastClickTime = 0
                    lastClickWid  = nil
                else
                    -- Single click: add tag (only if not already tagged)
                    if not tags[wid] then
                        tagWindow(hit)
                    end
                    lastClickTime = now
                    lastClickWid  = wid
                end
            end)

            return false
        end
    )
    clickWatcher:start()
end

local function stopClickCapture()
    if clickWatcher then
        clickWatcher:stop()
        clickWatcher = nil
    end
end

-- ── Tag mode toggle ───────────────────────────────────────────

local function setTagMode(on)
    tagMode = on
    if on then
        startClickCapture()
        if not posTimer then
            posTimer = hs.timer.doEvery(UPDATE_HZ, updatePositions)
        end
        hs.alert.show("Tag Mode ON — click windows to number them\nF4 to exit")
    else
        stopClickCapture()
        hs.alert.show("Tag Mode OFF — " .. tagCount() .. " windows tagged")
    end
end

-- ── Public API ────────────────────────────────────────────────

function M.toggleTagMode()
    setTagMode(not tagMode)
end

function M.reset()
    setTagMode(false)
    for wid in pairs(badges) do destroyBadge(wid) end
    tags    = {}
    badges  = {}
    if posTimer then posTimer:stop(); posTimer = nil end
    hs.alert.show("Tags cleared")
end

-- Returns tagged windows sorted by tag number, for use by layout functions
function M.taggedWindows()
    local ordered = {}
    for wid, n in pairs(tags) do
        local win = hs.window.get(wid)
        if win then table.insert(ordered, { win=win, n=n }) end
    end
    table.sort(ordered, function(a,b) return a.n < b.n end)
    local result = {}
    for _, entry in ipairs(ordered) do table.insert(result, entry.win) end
    return result
end

function M.hasTagged()
    return tagCount() > 0
end

-- Keep badges updated even when tag mode is off (windows move)
posTimer = hs.timer.doEvery(UPDATE_HZ, updatePositions)

return M
