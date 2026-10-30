-- Cut an Omarchy background intro from the playing video.
-- Shipped by the girgie.intro-cut shell plugin, which links it into mpv.
--
--   l        set A (start), press again to set B (end)  -- mpv built-in ab-loop
--   Shift+X  export A..B as a silent intro + its matching last-frame still
--
-- Output joins the current theme's background rotation as a pair Omarchy recognizes:
--   ~/.config/omarchy/backgrounds/<theme>/<name>.png          the background still
--   ~/.config/omarchy/backgrounds/<theme>/intros/<name>.mp4   the intro video
-- Without a current theme it falls back to ~/Pictures/Intros.

local utils = require "mp.utils"

local home = os.getenv("HOME")
local default_length = 6
local max_width = 2560

local function slug(s)
  s = s:lower():gsub("[^%w]+", "-"):gsub("^-+", ""):gsub("-+$", "")
  return s:sub(1, 40):gsub("-+$", "")
end

local function current_theme()
  local f = io.open(home .. "/.local/state/omarchy/current/theme.name")
  if not f then return nil end
  local theme = (f:read("*l") or ""):match("^[%w._-]+$")
  f:close()
  if theme and theme:sub(1, 1) ~= "." then return theme end
end

local function output_dir()
  local theme = current_theme()
  if theme then return home .. "/.config/omarchy/backgrounds/" .. theme, theme end
  return home .. "/Pictures/Intros", nil
end

local function run(args, done)
  mp.command_native_async({
    name = "subprocess",
    args = args,
    playback_only = false,
    capture_stderr = true,
  }, function(_, res)
    done(res and res.status == 0, res and res.stderr or "")
  end)
end

local function fail(step, err)
  mp.msg.error(step .. " failed: " .. err)
  mp.osd_message("Intro export failed (" .. step .. "), see terminal", 5)
end

local function export()
  local path = mp.get_property("path")
  if not path then return end

  local a = mp.get_property_number("ab-loop-a") or mp.get_property_number("time-pos", 0)
  local b = mp.get_property_number("ab-loop-b") or (a + default_length)
  if b < a then a, b = b, a end
  local length = b - a

  local out_dir, theme = output_dir()
  local intros_dir = utils.join_path(out_dir, "intros")
  local name = slug(mp.get_property("filename/no-ext", "intro")) .. "-" .. math.floor(a)
  local still = utils.join_path(out_dir, name .. ".png")
  local video = utils.join_path(intros_dir, name .. ".mp4")
  -- Work files stay in intros/, where Omarchy never looks for stills, and are
  -- renamed into place only once complete.
  local video_part = utils.join_path(intros_dir, "." .. name .. ".part.mp4")
  local still_part = utils.join_path(intros_dir, "." .. name .. ".part.png")

  mp.osd_message(string.format("Exporting intro %.2fs ...", length), 30)

  run({ "mkdir", "-p", intros_dir }, function()
    run({
      "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
      "-ss", string.format("%.3f", a), "-i", path, "-t", string.format("%.3f", length),
      "-map", "0:v:0", "-an", "-sn",
      "-vf", "scale='min(" .. max_width .. ",iw)':-2,format=yuv420p",
      "-c:v", "libx264", "-preset", "slow", "-crf", "18", "-movflags", "+faststart",
      video_part,
    }, function(ok, err)
      if not ok then os.remove(video_part); return fail("video", err) end
      -- Decode the tail of the finished clip so the still matches its last frame exactly.
      run({
        "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
        "-sseof", "-0.5", "-i", video_part, "-update", "1", still_part,
      }, function(ok2, err2)
        if not ok2 then os.remove(video_part); os.remove(still_part); return fail("still", err2) end
        -- Video first: a still without its clip would appear as a plain background.
        os.rename(video_part, video)
        os.rename(still_part, still)
        local note = (length < 5 or length > 7) and "  (Omarchy suggests 5-7s)" or ""
        mp.msg.info("Intro saved: " .. video)
        mp.msg.info("Still saved: " .. still)
        mp.osd_message(string.format("Saved %s to %s (%.2fs)%s", name, theme or "~/Pictures/Intros", length, note), 5)
      end)
    end)
  end)
end

mp.add_key_binding("X", "export", export)
