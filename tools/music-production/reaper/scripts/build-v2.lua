-- build-v2.lua — builds the melody-first BGM v2 project in REAPER, saves the
-- .rpp and renders promo/audio/bgm-v2.wav (48 kHz stereo, REAPER action 42230).
-- Installed as __startup.lua by promo/reaper/build-v2.ps1; deferred so actions
-- run after the main loop is up.
local D = "D:/hsu_flutter/promo/reaper/"
local PROJ = D .. "bgm-v2.rpp"
local OUT_DIR = "D:/hsu_flutter/promo/audio"
local LOG = D .. "build-v2.log"
local SR = 48000
local MASTER_VOL = 0.265

local function log(s)
  local f = io.open(LOG, "a")
  if f then f:write(tostring(s) .. "\n"); f:close() end
end

local data = dofile(D .. "build-data.lua")
log("data tracks=" .. #data.tracks .. " bpm=" .. data.bpm)

local PRESETS = {
  lead = {{0, 0.002}, {1, 0.22}, {2, 0.12}, {3, 0.3}, {4, 0.55}, {5, 0.72}, {6, 0.3}, {7, 0.1}, {9, 0.45}, {11, 0.5005}},
  leadDbl = {{0, 0.002}, {1, 0.2}, {2, 0.05}, {3, 0.56}, {4, 0.4}, {5, 0.6}, {6, 0.3}, {7, 0.05}, {9, 0.5}, {11, 0.4995}},
  counter = {{0, 0.012}, {1, 0.4}, {2, 0.0}, {3, 0.18}, {4, 0.6}, {5, 0.62}, {6, 0.4}, {7, 0.08}, {9, 0.65}, {11, 0.5}},
  pad = {{0, 0.42}, {1, 0.75}, {2, 0.06}, {3, 0.22}, {4, 0.55}, {5, 0.4}, {6, 0.5}, {7, 0.18}, {9, 0.9}, {11, 0.5}},
  bass = {{0, 0.004}, {1, 0.12}, {2, 0.05}, {3, 0.2}, {4, 0.6}, {5, 0.65}, {6, 0.22}, {7, 0.35}, {9, 0.55}, {11, 0.5}},
}

local function addTrack(name, idx)
  reaper.InsertTrackAtIndex(idx, true)
  local tr = reaper.GetTrack(0, idx)
  reaper.GetSetMediaTrackInfo_String(tr, "P_NAME", name, true)
  return tr
end

local function insertNotes(tr, notes)
  local item = reaper.CreateNewMIDIItemInProj(tr, 0, 40, false)
  local take = reaper.GetActiveTake(item)
  for _, n in ipairs(notes) do
    local b, p, d, v = n[1], n[2], n[3], n[4]
    local p1 = math.floor(b * 960 + 0.5)
    local p2 = math.floor((b + d) * 960 + 0.5)
    if p2 <= p1 then p2 = p1 + 1 end
    reaper.MIDI_InsertNote(take, false, false, p1, p2, 0, p, v, false)
  end
  reaper.MIDI_Sort(take)
  return item
end

local function build()
  reaper.GetSetProjectInfo(0, "PROJECT_SRATE", SR, true)
  reaper.GetSetProjectInfo(0, "PROJECT_SRATE_USE", 1, true)
  reaper.SetCurrentBPM(0, data.bpm, true)

  local created = {}
  for i, t in ipairs(data.tracks) do
    if t.name == "PAD" then
      -- A genuinely stereo pad: two hard-panned copies, 20 ms Haas offset and
      -- a tiny opposite detune. No phase-flip tricks; bass/kick/lead stay mono.
      local halves = {
        {name = "PAD L", pan = -1.0, vol = t.vol * 2.1, offset = 0.0, detune = 0.4995},
        {name = "PAD R", pan = 1.0, vol = t.vol * 2.1, offset = 0.02, detune = 0.5005},
      }
      for _, h in ipairs(halves) do
        local tr = addTrack(h.name, reaper.CountTracks(0))
        reaper.SetMediaTrackInfo_Value(tr, "D_VOL", h.vol)
        reaper.SetMediaTrackInfo_Value(tr, "D_PAN", h.pan)
        local fx = reaper.TrackFX_AddByName(tr, "ReaSynth", false, -1)
        if fx < 0 then
          log("ERROR ReaSynth missing on " .. h.name)
        else
          for _, pv in ipairs(PRESETS.pad) do
            reaper.TrackFX_SetParam(tr, fx, pv[1], pv[2])
          end
          reaper.TrackFX_SetParam(tr, fx, 11, h.detune)
        end
        local item = insertNotes(tr, t.notes)
        reaper.SetMediaItemInfo_Value(item, "D_POSITION", h.offset)
        created[#created + 1] = {tr = tr, send = t.send}
        log(string.format("track %-9s synth notes=%d vol=%.3f pan=%.2f offset=%.3f", h.name, #t.notes, h.vol, h.pan, h.offset))
      end
    else
      local tr = addTrack(t.name, reaper.CountTracks(0))
      reaper.SetMediaTrackInfo_Value(tr, "D_VOL", t.vol)
      reaper.SetMediaTrackInfo_Value(tr, "D_PAN", t.pan or 0)
      if t.kind == "synth" then
        local fx = reaper.TrackFX_AddByName(tr, "ReaSynth", false, -1)
        if fx < 0 then
          log("ERROR ReaSynth missing on " .. t.name)
        else
          for _, pv in ipairs(PRESETS[t.preset] or PRESETS.lead) do
            reaper.TrackFX_SetParam(tr, fx, pv[1], pv[2])
          end
        end
      else
        local fx = reaper.TrackFX_AddByName(tr, "ReaSamplOmatic5000", false, -1)
        if fx < 0 then
          log("ERROR RS5K missing on " .. t.name)
        else
          reaper.TrackFX_SetNamedConfigParm(tr, fx, "FILE", D .. t.sample)
          reaper.TrackFX_SetParam(tr, fx, 0, 0.85)
        end
      end
      insertNotes(tr, t.notes)
      created[#created + 1] = {tr = tr, send = t.send}
      log(string.format("track %-9s %-6s notes=%d vol=%.2f pan=%.2f", t.name, t.kind, #t.notes, t.vol, t.pan or 0))
    end
  end

  -- reverb return
  local verb = addTrack("VERB", reaper.CountTracks(0))
  reaper.SetMediaTrackInfo_Value(verb, "D_VOL", 0.5)
  local vfx = reaper.TrackFX_AddByName(verb, "ReaVerbate", false, -1)
  if vfx >= 0 then
    reaper.TrackFX_SetParamNormalized(verb, vfx, 0, 1.0) -- wet 0 dB
    reaper.TrackFX_SetParamNormalized(verb, vfx, 1, 0.0) -- dry -inf
    reaper.TrackFX_SetParamNormalized(verb, vfx, 2, 0.55) -- room
    reaper.TrackFX_SetParamNormalized(verb, vfx, 3, 0.55) -- damping
    reaper.TrackFX_SetParamNormalized(verb, vfx, 4, 1.0) -- width
  else
    log("ERROR ReaVerbate missing")
  end
  for _, c in ipairs(created) do
    if c.send and c.send > 0 then
      local si = reaper.CreateTrackSend(c.tr, verb)
      if si >= 0 then
        reaper.SetTrackSendInfo_Value(c.tr, 0, si, "D_VOL", c.send)
      end
    end
  end

  reaper.SetMediaTrackInfo_Value(reaper.GetMasterTrack(0), "D_VOL", MASTER_VOL)
  reaper.Main_SaveProjectEx(0, PROJ, 0)
  log("saved " .. PROJ)

  reaper.GetSetProjectInfo_String(0, "RENDER_FILE", OUT_DIR, true)
  reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "bgm-v2", true)
  reaper.GetSetProjectInfo(0, "RENDER_BOUNDSFLAG", 0, true)
  reaper.GetSetProjectInfo(0, "RENDER_STARTPOS", 0, true)
  reaper.GetSetProjectInfo(0, "RENDER_ENDPOS", 40.0, true)
  reaper.GetSetProjectInfo(0, "RENDER_SETTINGS", 0, true)
  reaper.GetSetProjectInfo_String(0, "RENDER_FORMAT", "evaw", true)
  reaper.GetSetProjectInfo(0, "RENDER_SRATE", SR, true)
  reaper.GetSetProjectInfo(0, "RENDER_CHANNELS", 2, true)
  reaper.Main_OnCommand(42230, 0)
  log("render returned; exists=" .. tostring(io.open(OUT_DIR .. "/bgm-v2.wav", "rb") ~= nil))
end

local function main()
  local ok, err = pcall(build)
  log("main ok=" .. tostring(ok) .. " err=" .. tostring(err))
  reaper.defer(function() reaper.Main_OnCommand(40004, 0) end)
end

reaper.defer(main)
