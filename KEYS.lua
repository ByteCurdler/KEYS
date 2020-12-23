--[ KEYS v1.2 ]--

-- Modified from https://gist.github.com/boxmein/5730768
-- Keyboard sensor element (KEYS)

-- Set TMP to the scan code(!) to enable
-- Set TMP2 (optional) to the modifier code to set modifiers
-- Use the debug HUD to see the values before setting them 

-- originally by boxmein
-- modified by ILikePython256 on GitHub

-- Changelog:

--  v1.0 - v1.2: (Changelog not used yet)
--  v1.3: KSNS now blocks keys it's set to from activating system functions,
--       e.g. a KEYS set to Z will block the zoom function (except while paused)

-- This version modified to use the Event API

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ',\n'
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

local KEYS_id = elements.allocate("ilikepython", "KEYS")

local lastkeyn = 0
local lastmod = 0
local pressing = false


function KEYS_is_active (tmp, tmp2)
  if pressing then
    -- allow tmp2 to set key modifications (for the sake of shift, ctrl, etc)
    if tmp2 ~= -1 then
    	if lastmod ~= tmp2 then return false end
    end


    if tmp == lastkeyn then
          return true
    end
  end
  return false
end

function KEYS_update (index, partx, party, surround_space, nt)
  local tmp = tpt.get_property("tmp", index)
  local tmp2 = tpt.get_property("tmp2", index)

  
  if KEYS_is_active(tmp, tmp2) then
    local t = {sim.partNeighbours(partx, party, 2)}

    -- why would t be nil with particles nearby ;_;
    if t == nil then return 0 end
    
  	tpt.set_property("life", math.min(tpt.get_property("life", index)+1, 5), index)

    for vTwo, v in ipairs(t[1]) do 
      if bit.band(elements.property(tpt.get_property("type", v),"Properties"),elements.PROP_CONDUCTS) == 32 then
        
        local rx, ry = sim.partPosition(v)
        tpt.create(rx, ry, "SPRK")
      end
    end
  else
  	tpt.set_property("life", math.max(tpt.get_property("life", index)-1, 0), index)
  end
end

function KEYS_graphics (index, colr, colg, colb)
	cola = 255
	mult = 0.5 + tpt.get_property("life", index)/10
	dcolor = tpt.get_property("dcolor", index)
	if dcolor ~= 0 then
		cola = bit.band(dcolor, 0xFF000000) / 0x1000000
		colr = bit.band(dcolor, 0x00FF0000) / 0x10000
		colg = bit.band(dcolor, 0x0000FF00) / 0x100
		colb = bit.band(dcolor, 0x000000FF)
	end
	--cache, pixel_mode, cola, colr, colg, colb, firea, firer, fireg, fireb
	return 0, 0x1001, cola, colr*mult, colg*mult, colb*mult, 0, 0, 0, 0
	-- 0x1001 is bitmask for NO_DECO and PMODE_FLAT
end

function keyup (key, scan, _, shift, ctrl, alt) 
  lastmod = 0
  if shift then lastmod = lastmod + 1 end
  if ctrl then lastmod = lastmod + 2 end
  if alt then lastmod = lastmod + 4 end
  lastkeyn = scan
  pressing = false
end

function keydown (key, scan, isRepeat, shift, ctrl, alt)
	if isRepeat then return end
  lastmod = 0
  if shift then lastmod = lastmod + 1 end
  if ctrl then lastmod = lastmod + 2 end
  if alt then lastmod = lastmod + 4 end
  lastkeyn = scan
  pressing = true
  if tpt.set_pause() == 0 then --Don't block while paused
		for i in sim.parts() do
			part = tpt.parts[i]
			if part.type == KEYS_id then
				if part.tmp == scan and (part.tmp2 == -1 or part.tmp2 == lastmod) then
					return false
				end
			end
		end
  end
end

event.register(event.keypress, keydown)
event.register(event.keyrelease, keyup)

elements.element(KEYS_id, elements.element(elements.DEFAULT_PT_DMND))
elements.property(KEYS_id, "Name", "KEYS")
elements.property(KEYS_id, "Colour", "0xFF00FFFF") 
elements.property(KEYS_id, "Description", "Keyboard Sensor. Creates a spark when a key with code equal to tmp and (if tmp2 is not -1) modifiers equal to tmp2 is pressed.") 
elements.property(KEYS_id, "MenuSection", elements.SC_SENSOR)
elements.property(KEYS_id, "Update", KEYS_update) 
elements.property(KEYS_id, "Graphics", KEYS_graphics) 

-- # ====================================================================== # --
-- # Debugging


  -- for the sake of debug only, some might find it of use
function getmodtext(lastmod)
  modtext = ""
  if lastmod == 0 then
    return "none"
  end
  if bit.band(lastmod, 2) == 2 then
    modtext = modtext .. "CTRL " 
  end
  if bit.band(lastmod, 4) == 4 then
    modtext = modtext .. "ALT "
  end
  if bit.band(lastmod, 1) == 1 then
    modtext = modtext .. "SHIFT " 
  end
  return modtext
end 

function debuglog ()
  if ren.debugHUD() ==  1 then
    tpt.drawtext(20, 50, 
      "KEYS 1.3" ..
      "\nkeycode: " .. lastkeyn .. 
      "\nmod: " .. lastmod .. " / " .. getmodtext(lastmod) .. 
      "\npressing: " .. tostring(pressing))
  end
end

event.register(event.tick, debuglog) 

