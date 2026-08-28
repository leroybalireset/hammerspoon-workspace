-- ============================================================
-- LAYOUT PALETTE  (webview-based — draggable, clickable)
-- F5 = show/hide
-- ============================================================

local M = {}

local PAL_W = 780
local PAL_H = 560

local winTags   = nil
local webview   = nil
local visible   = false

-- ── Screen center ─────────────────────────────────────────────

local function paletteFrame()
    -- Bottom-right of the primary (Mi) monitor, above the Dock/taskbar
    local screen = hs.screen.primaryScreen()
    local sf  = screen:fullFrame()   -- full pixels
    local usf = screen:frame()       -- usable area (excludes Dock)
    local margin = 12
    return hs.geometry.rect(
        sf.x + sf.w - PAL_W - margin,
        usf.y + usf.h - PAL_H - margin,
        PAL_W, PAL_H
    )
end

-- ── Screen layout helpers ─────────────────────────────────────

local function getScreenFrames()
    local lg, mi
    for _, s in ipairs(hs.screen.allScreens()) do
        local f = s:fullFrame()
        if f.x < 0 then lg = f else mi = f end
    end
    if not lg then
        local all = hs.screen.allScreens()
        lg = all[1] and all[1]:fullFrame()
        mi = all[2] and all[2]:fullFrame()
    end
    return lg, mi
end

local function snapWin(win, f)
    if not win then return end
    if win:isMinimized() then win:unminimize() end
    win:setFrame(hs.geometry.rect(f.x, f.y, f.w, f.h), 0)
end

local function getWindows()
    if winTags and winTags.hasTagged() then
        return winTags.taggedWindows()
    end
    local wins = {}
    for _, win in ipairs(hs.window.orderedWindows()) do
        if win:isStandard() and not win:isMinimized() then
            table.insert(wins, win)
        end
    end
    table.sort(wins, function(a, b) return a:frame().x < b:frame().x end)
    return wins
end

-- ── Layout definitions ────────────────────────────────────────

local LAYOUTS = {
    {
        id    = "ai",
        label = "AI Layout",
        desc  = "½ · ¼ · ¼  |  4 equal",
        -- preview: list of {screen, x, y, w, h} as fractions, color class
        blocks = {
            { s="L", x=0,    y=0, w=0.50, h=1, c="main" },
            { s="L", x=0.50, y=0, w=0.25, h=1, c="b" },
            { s="L", x=0.75, y=0, w=0.25, h=1, c="c" },
            { s="R", x=0,    y=0, w=0.25, h=1, c="b" },
            { s="R", x=0.25, y=0, w=0.25, h=1, c="c" },
            { s="R", x=0.50, y=0, w=0.25, h=1, c="b" },
            { s="R", x=0.75, y=0, w=0.25, h=1, c="c" },
        },
        apply = function(wins)
            local lg, mi = getScreenFrames()
            if not lg or not mi then return end
            local slots = {
                { x=lg.x,                      y=lg.y, w=math.floor(lg.w/2),          h=lg.h },
                { x=lg.x+math.floor(lg.w/2),   y=lg.y, w=math.floor(lg.w/4),          h=lg.h },
                { x=lg.x+math.floor(lg.w*3/4), y=lg.y, w=lg.w-math.floor(lg.w*3/4),   h=lg.h },
                { x=mi.x,                      y=mi.y, w=math.floor(mi.w/4),          h=mi.h },
                { x=mi.x+math.floor(mi.w/4),   y=mi.y, w=math.floor(mi.w/4),          h=mi.h },
                { x=mi.x+math.floor(mi.w/2),   y=mi.y, w=math.floor(mi.w/4),          h=mi.h },
                { x=mi.x+math.floor(mi.w*3/4), y=mi.y, w=mi.w-math.floor(mi.w*3/4),   h=mi.h },
            }
            for i, win in ipairs(wins) do
                if slots[i] then snapWin(win, slots[i]) end
            end
        end,
    },
    {
        id    = "even",
        label = "Even Split",
        desc  = "Equal columns per monitor",
        blocks = {
            { s="L", x=0,    y=0, w=0.33, h=1, c="main" },
            { s="L", x=0.33, y=0, w=0.34, h=1, c="b" },
            { s="L", x=0.67, y=0, w=0.33, h=1, c="c" },
            { s="R", x=0,    y=0, w=0.33, h=1, c="b" },
            { s="R", x=0.33, y=0, w=0.34, h=1, c="c" },
            { s="R", x=0.67, y=0, w=0.33, h=1, c="main" },
        },
        apply = function(wins)
            local lg, mi = getScreenFrames()
            if not lg or not mi then return end
            local half = math.ceil(#wins / 2)
            local lgW, miW = {}, {}
            for i, w in ipairs(wins) do
                if i <= half then table.insert(lgW, w) else table.insert(miW, w) end
            end
            local function snap(group, F)
                local n = #group; if n == 0 then return end
                local cw = math.floor(F.w / n)
                for i, win in ipairs(group) do
                    local x = F.x + (i-1)*cw
                    local w = (i==n) and (F.x+F.w-x) or cw
                    snapWin(win, {x=x, y=F.y, w=w, h=F.h})
                end
            end
            snap(lgW, lg); snap(miW, mi)
        end,
    },
    {
        id    = "focus",
        label = "Focus Split",
        desc  = "⅔ main · ⅓ shared",
        blocks = {
            { s="L", x=0,    y=0, w=0.67, h=1, c="main" },
            { s="L", x=0.67, y=0, w=0.33, h=1, c="b" },
            { s="R", x=0,    y=0, w=0.67, h=1, c="main" },
            { s="R", x=0.67, y=0, w=0.33, h=1, c="b" },
        },
        apply = function(wins)
            local lg, mi = getScreenFrames()
            if not lg or not mi then return end
            local half = math.ceil(#wins / 2)
            local lgW, miW = {}, {}
            for i, w in ipairs(wins) do
                if i <= half then table.insert(lgW, w) else table.insert(miW, w) end
            end
            local function snap(group, F)
                local n = #group; if n == 0 then return end
                local mw = math.floor(F.w * 2/3)
                snapWin(group[1], {x=F.x, y=F.y, w=mw, h=F.h})
                local sw = F.w - mw
                local slw = n > 1 and math.floor(sw / (n-1)) or 0
                for i = 2, n do
                    local x = F.x + mw + (i-2)*slw
                    local w = (i==n) and (F.x+F.w-x) or slw
                    snapWin(group[i], {x=x, y=F.y, w=w, h=F.h})
                end
            end
            snap(lgW, lg); snap(miW, mi)
        end,
    },
    {
        id    = "lgfull",
        label = "LG Full · Mi Split",
        desc  = "1 full left · rest on right",
        blocks = {
            { s="L", x=0,    y=0, w=1,    h=1, c="main" },
            { s="R", x=0,    y=0, w=0.33, h=1, c="b" },
            { s="R", x=0.33, y=0, w=0.34, h=1, c="c" },
            { s="R", x=0.67, y=0, w=0.33, h=1, c="b" },
        },
        apply = function(wins)
            local lg, mi = getScreenFrames()
            if not lg or not mi then return end
            snapWin(wins[1], lg)
            local rest = {}
            for i = 2, #wins do table.insert(rest, wins[i]) end
            local n = #rest
            for i, win in ipairs(rest) do
                local cw = math.floor(mi.w / math.max(n,1))
                local x = mi.x + (i-1)*cw
                local w = (i==n) and (mi.x+mi.w-x) or cw
                snapWin(win, {x=x, y=mi.y, w=w, h=mi.h})
            end
        end,
    },
    {
        id    = "stack",
        label = "Stack · 3 Right",
        desc  = "2 stacked + sidebar · 3 cols",
        blocks = {
            { s="L", x=0,    y=0,    w=0.67, h=0.5, c="main" },
            { s="L", x=0,    y=0.5,  w=0.67, h=0.5, c="b" },
            { s="L", x=0.67, y=0,    w=0.33, h=1,   c="c" },
            { s="R", x=0,    y=0, w=0.33, h=1, c="b" },
            { s="R", x=0.33, y=0, w=0.34, h=1, c="c" },
            { s="R", x=0.67, y=0, w=0.33, h=1, c="b" },
        },
        apply = function(wins)
            local lg, mi = getScreenFrames()
            if not lg or not mi then return end
            local mw = math.floor(lg.w * 2/3)
            local hh = math.floor(lg.h / 2)
            snapWin(wins[1], {x=lg.x,     y=lg.y,    w=mw,        h=hh})
            snapWin(wins[2], {x=lg.x,     y=lg.y+hh, w=mw,        h=lg.h-hh})
            snapWin(wins[3], {x=lg.x+mw,  y=lg.y,    w=lg.w-mw,   h=lg.h})
            local rest = {}
            for i = 4, #wins do table.insert(rest, wins[i]) end
            local n = #rest
            for i, win in ipairs(rest) do
                local cw = math.floor(mi.w / math.max(n,1))
                local x = mi.x + (i-1)*cw
                local w = (i==n) and (mi.x+mi.w-x) or cw
                snapWin(win, {x=x, y=mi.y, w=w, h=mi.h})
            end
        end,
    },
    {
        id    = "quarters",
        label = "Quarters",
        desc  = "4 equal on each monitor",
        blocks = {
            { s="L", x=0,    y=0, w=0.25, h=1, c="main" },
            { s="L", x=0.25, y=0, w=0.25, h=1, c="b" },
            { s="L", x=0.50, y=0, w=0.25, h=1, c="c" },
            { s="L", x=0.75, y=0, w=0.25, h=1, c="b" },
            { s="R", x=0,    y=0, w=0.25, h=1, c="b" },
            { s="R", x=0.25, y=0, w=0.25, h=1, c="c" },
            { s="R", x=0.50, y=0, w=0.25, h=1, c="main" },
            { s="R", x=0.75, y=0, w=0.25, h=1, c="b" },
        },
        apply = function(wins)
            local lg, mi = getScreenFrames()
            if not lg or not mi then return end
            local lgW, miW = {}, {}
            for i, w in ipairs(wins) do
                if i <= 4 then table.insert(lgW, w) else table.insert(miW, w) end
            end
            local function snap4(group, F)
                local n = math.min(#group, 4)
                for i = 1, n do
                    local cw = math.floor(F.w / 4)
                    local x = F.x + (i-1)*cw
                    local w = (i==4) and (F.x+F.w-x) or cw
                    snapWin(group[i], {x=x, y=F.y, w=w, h=F.h})
                end
            end
            snap4(lgW, lg); snap4(miW, mi)
        end,
    },
}

-- ── HTML builder ──────────────────────────────────────────────

local function blocksToCSS(blocks)
    -- Returns inline style divs for the preview boxes
    local parts = {}
    -- LG preview area = left 53%, Mi = right 44%, gap 3%
    local lgPct = 53
    local miPct = 44
    for _, b in ipairs(blocks) do
        local areaX, areaW
        if b.s == "L" then
            areaX = 0; areaW = lgPct
        else
            areaX = lgPct + 3; areaW = miPct
        end
        local left   = areaX + b.x * areaW
        local top    = b.y * 100
        local width  = b.w * areaW
        local height = b.h * 100

        local colors = {
            main = "#3d8ef0",
            b    = "#2db87a",
            c    = "#e8702a",
        }
        local col = colors[b.c] or "#3d8ef0"
        table.insert(parts, string.format(
            '<div style="position:absolute;left:%.1f%%;top:%.1f%%;width:%.1f%%;height:%.1f%%;background:%s;border-radius:2px;opacity:0.88;box-sizing:border-box;border:1px solid rgba(255,255,255,0.15);"></div>',
            left, top, width - 0.5, height - 1, col
        ))
    end
    return table.concat(parts, "\n")
end

local function readConfig()
    local f = io.open(os.getenv("HOME") .. "/.hammerspoon/config.lua", "r")
    if not f then return "-- config.lua not found" end
    local s = f:read("*a")
    f:close()
    -- Escape for embedding in HTML JS string
    s = s:gsub("\\", "\\\\"):gsub("`", "\\`"):gsub("$", "\\$")
    return s
end

local function buildHTML()
    local tiles = {}
    for _, layout in ipairs(LAYOUTS) do
        local preview = blocksToCSS(layout.blocks)
        local divider = '<div style="position:absolute;left:53%%;top:0;width:1px;height:100%%;background:rgba(255,255,255,0.2);"></div>'
        table.insert(tiles, string.format([[
<div class="tile" onclick="webkit.messageHandlers.palette.postMessage({path:'layout?id=%s'})">
  <div class="preview">%s%s</div>
  <div class="label">%s</div>
  <div class="desc">%s</div>
</div>]], layout.id, divider, preview, layout.label, layout.desc))
    end

    local configContent = readConfig()

    -- Build app dropdown options from /Applications
    local appOptions = {}
    local handle = io.popen("find /Applications -maxdepth 2 -name '*.app' | sed 's|.*/||;s|\\.app$||' | sort 2>/dev/null")
    if handle then
        for name in handle:lines() do
            if name ~= "" then
                table.insert(appOptions, string.format('<option value="%s">%s</option>', name, name))
            end
        end
        handle:close()
    end

    return string.format([[<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    background: #18181f;
    color: #fff;
    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
    font-size: 13px;
    overflow: hidden;
    height: 100vh;
    display: flex;
    flex-direction: column;
  }
  .header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 10px 14px 8px;
    background: #12121a;
    border-bottom: 1px solid rgba(255,255,255,0.08);
    -webkit-app-region: drag;
    flex-shrink: 0;
  }
  .header-left { pointer-events: none; }
  .title { font-size: 14px; font-weight: 700; color: #7ab8ff; }
  .subtitle { font-size: 10px; color: #888; margin-top: 2px; }
  .header-btns { display: flex; gap: 8px; -webkit-app-region: no-drag; }
  .btn {
    padding: 4px 12px; border-radius: 6px; border: none;
    font-size: 11px; font-weight: 600; cursor: pointer; color: #fff;
  }
  .btn-reset  { background: #c47a1a; }
  .btn-reset:hover { background: #d88c20; }
  .btn-close  { background: #c0392b; }
  .btn-close:hover { background: #d44; }
  .btn-save   { background: #1a7a4a; }
  .btn-save:hover { background: #20963c; }
  .btn-reload { background: #3a5a9a; }
  .btn-reload:hover { background: #4a6ab0; }

  /* Tabs */
  .tabs {
    display: flex;
    background: #12121a;
    border-bottom: 1px solid rgba(255,255,255,0.08);
    flex-shrink: 0;
    -webkit-app-region: no-drag;
  }
  .tab {
    padding: 7px 20px;
    font-size: 12px;
    font-weight: 600;
    color: #666;
    cursor: pointer;
    border-bottom: 2px solid transparent;
    user-select: none;
  }
  .tab.active { color: #7ab8ff; border-bottom-color: #7ab8ff; }
  .tab:hover:not(.active) { color: #aaa; }

  /* Panels */
  .panel { display: none; flex: 1; overflow: hidden; flex-direction: column; }
  .panel.active { display: flex; }

  /* Layout grid */
  .grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 10px;
    padding: 12px 14px;
    overflow-y: auto;
    flex: 1;
  }
  .tile {
    background: #22222e;
    border: 1px solid rgba(255,255,255,0.1);
    border-radius: 8px;
    cursor: pointer;
    padding: 8px 8px 6px;
    transition: background 0.15s, border-color 0.15s, transform 0.1s;
    display: flex;
    flex-direction: column;
    user-select: none;
  }
  .tile:hover { background: #2a3a5a; border-color: #4a7fd4; transform: scale(1.02); }
  .tile:active { transform: scale(0.98); background: #1e3060; }
  .preview {
    position: relative;
    width: 100%%;
    height: 72px;
    background: #0e0e18;
    border-radius: 4px;
    overflow: hidden;
    margin-bottom: 6px;
    flex-shrink: 0;
  }
  .label { font-size: 11px; font-weight: 700; color: #eee; text-align: center; }
  .desc  { font-size: 9px; color: #777; text-align: center; margin-top: 2px; }

  /* Config editor */
  .editor-toolbar {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 8px 14px;
    background: #12121a;
    border-bottom: 1px solid rgba(255,255,255,0.08);
    flex-shrink: 0;
    flex-wrap: wrap;
  }
  .editor-toolbar span { font-size: 10px; color: #666; margin-left: auto; }
  .app-select {
    background: #22222e;
    color: #c8d0e0;
    border: 1px solid rgba(255,255,255,0.15);
    border-radius: 6px;
    font-size: 11px;
    padding: 4px 8px;
    cursor: pointer;
    outline: none;
    max-width: 200px;
  }
  .app-select:focus { border-color: #4a7fd4; }
  #configEditor {
    flex: 1;
    background: #0d0d14;
    color: #c8d0e0;
    font-family: "SF Mono", "Menlo", "Monaco", monospace;
    font-size: 12px;
    line-height: 1.6;
    padding: 12px 14px;
    border: none;
    outline: none;
    resize: none;
    tab-size: 4;
    white-space: pre;
    overflow: auto;
    user-select: text;
    -webkit-user-select: text;
  }
  .status-bar {
    padding: 4px 14px;
    font-size: 10px;
    color: #555;
    background: #0a0a10;
    border-top: 1px solid rgba(255,255,255,0.05);
    flex-shrink: 0;
  }
  .status-bar.ok  { color: #2db87a; }
  .status-bar.err { color: #e05555; }
</style>
</head>
<body>

<div class="header">
  <div class="header-left">
    <div class="title">Layout Palette</div>
    <div class="subtitle">Tag windows with F4 · pick a layout · windows snap in tag order</div>
  </div>
  <div class="header-btns">
    <button class="btn btn-reset" onclick="webkit.messageHandlers.palette.postMessage({path:'palette?action=reset'})">Reset Tags</button>
    <button class="btn btn-close" onclick="webkit.messageHandlers.palette.postMessage({path:'palette?action=close'})">Close</button>
  </div>
</div>

<div class="tabs">
  <div class="tab active" onclick="switchTab('layouts')">Layouts</div>
  <div class="tab" onclick="switchTab('config')">config.lua</div>
</div>

<!-- Layouts panel -->
<div class="panel active" id="panel-layouts">
  <div class="grid">%s</div>
</div>

<!-- Config editor panel -->
<div class="panel" id="panel-config">
  <div class="editor-toolbar">
    <button class="btn btn-save" onclick="saveConfig()">Save</button>
    <button class="btn btn-reload" onclick="saveAndReload()">Save &amp; Reload</button>
    <select class="app-select" id="appPicker" onchange="insertApp(this)">
      <option value="">⌥ Insert app name...</option>
      %s
    </select>
    <span id="editorHint">⌘S save · ⌘⇧S save &amp; reload</span>
  </div>
  <textarea id="configEditor" spellcheck="false">%s</textarea>
  <div class="status-bar" id="statusBar">Ready</div>
</div>

<script>
  function switchTab(name) {
    document.querySelectorAll('.tab').forEach(function(t, i) {
      t.classList.toggle('active', ['layouts','config'][i] === name);
    });
    document.querySelectorAll('.panel').forEach(function(p) {
      p.classList.remove('active');
    });
    document.getElementById('panel-' + name).classList.add('active');
  }

  function saveConfig() {
    var content = document.getElementById('configEditor').value;
    webkit.messageHandlers.palette.postMessage({path: 'config?action=save', content: content});
    setStatus('Saved', 'ok');
  }

  function saveAndReload() {
    var content = document.getElementById('configEditor').value;
    webkit.messageHandlers.palette.postMessage({path: 'config?action=reload', content: content});
    setStatus('Saved & reloading...', 'ok');
  }

  function setStatus(msg, cls) {
    var bar = document.getElementById('statusBar');
    bar.textContent = msg;
    bar.className = 'status-bar ' + (cls || '');
  }

  function insertApp(sel) {
    var name = sel.value;
    sel.value = '';
    if (!name) return;
    var el = document.getElementById('configEditor');
    el.focus();
    var s = el.selectionStart, e = el.selectionEnd;
    var insert = '"' + name + '"';
    el.value = el.value.substring(0, s) + insert + el.value.substring(e);
    el.selectionStart = el.selectionEnd = s + insert.length;
  }

  // Cmd+S to save
  document.addEventListener('keydown', function(e) {
    if ((e.metaKey || e.ctrlKey) && e.key === 's') {
      e.preventDefault();
      if (!document.getElementById('panel-config').classList.contains('active')) return;
      if (e.shiftKey) { saveAndReload(); } else { saveConfig(); }
    }
    // Tab key inserts spaces in editor
    if (e.key === 'Tab' && document.activeElement.id === 'configEditor') {
      e.preventDefault();
      var el = document.activeElement;
      var s = el.selectionStart, en = el.selectionEnd;
      el.value = el.value.substring(0, s) + '    ' + el.value.substring(en);
      el.selectionStart = el.selectionEnd = s + 4;
    }
  });
</script>
</body>
</html>]], table.concat(tiles, "\n"), table.concat(appOptions, "\n"), configContent)
end

-- ── URL handler ───────────────────────────────────────────────

local function handleURL(url, content)
    local str = tostring(url)

    if str:find("palette%?action=close") then
        M.hide()
        return true
    end

    if str:find("palette%?action=reset") then
        if winTags then winTags.reset() end
        hs.alert.show("Tags cleared")
        return true
    end

    if str:find("config%?action=save") or str:find("config%?action=reload") then
        if content and content ~= "" then
            local path = os.getenv("HOME") .. "/.hammerspoon/config.lua"
            local f = io.open(path, "w")
            if f then
                f:write(content)
                f:close()
                if str:find("reload") then
                    hs.timer.doAfter(0.3, function() hs.reload() end)
                end
            end
        end
        return true
    end

    local id = str:match("layout%?id=([%w_]+)")
    if id then
        for _, layout in ipairs(LAYOUTS) do
            if layout.id == id then
                local wins = getWindows()
                if #wins == 0 then
                    hs.alert.show("No windows to arrange")
                else
                    -- Snap first, then close palette so focus shift doesn't interfere
                    layout.apply(wins)
                    hs.timer.doAfter(0.3, function()
                        M.hide()
                        hs.alert.show(layout.label .. " — " .. #wins .. " windows")
                    end)
                end
                return true
            end
        end
    end

    return false
end

-- ── Public API ────────────────────────────────────────────────

function M.init(tags)
    winTags = tags
end

function M.show()
    M.hide()
    local pf = paletteFrame()
    local usercontent = hs.webview.usercontent.new("palette")
    usercontent:setCallback(function(msg)
        local body = msg.body
        if type(body) == "table" then
            handleURL("hammerspoon://" .. (body.path or ""), body.content)
        elseif type(body) == "string" then
            handleURL("hammerspoon://" .. body, nil)
        end
    end)
    webview = hs.webview.new(pf, { developerExtrasEnabled = false }, usercontent)
    webview:windowStyle({"titled", "closable", "resizable", "nonactivating"})
    webview:windowTitle("Layout Palette")
    webview:allowMagnificationGestures(false)
    webview:allowNewWindows(false)
    webview:level(hs.canvas.windowLevels.floating + 2)
    webview:html(buildHTML())
    webview:show()
    visible = true
end

function M.hide()
    if webview then
        webview:delete()
        webview = nil
    end
    visible = false
end

function M.toggle()
    if visible then M.hide() else M.show() end
end

function M.isVisible()
    return visible
end

return M
