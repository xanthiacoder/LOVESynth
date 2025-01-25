-- for ArkOS file system compatibility, tested on ArkOS 11272024 version 
love.filesystem.setIdentity("LOVESynth") 



local function file_exists(file)
	return love.filesystem.getInfo(file)
end

-- Set the platform the app is running on
local platform = love.system.getOS()

if platform ~= "Linux" and platform ~= "Windows" and platform ~= "OS X" then
	error("LOVESynth will not run on " .. platform)
end


-- check for ArkOS system
system = "" -- making global since global awareness required

if love.filesystem.getUserDirectory( ) == "/home/ark/" then
	system = "ArkOS"
	-- set up the save directory using LUA I/O to write
	os.execute("mkdir " .. love.filesystem.getSaveDirectory()) -- OS creation
	os.execute("mkdir " .. love.filesystem.getSaveDirectory() .. "//soundfonts")
	os.execute("mkdir " .. love.filesystem.getSaveDirectory() .. "//saves")
	os.execute("mkdir " .. love.filesystem.getSaveDirectory() .. "//exports")
else
	system = "Others"
	-- set up the save directory using Love FS (win, mac, linux)
	love.filesystem.createDirectory("soundfonts")
	love.filesystem.createDirectory("saves")
	love.filesystem.createDirectory("exports")
end



-- the default soundfont to load
local default_sf = "example.sf2"

-- if the soundfont doesn't exist in the save directory we copy it from
-- files and store it there
if not file_exists("soundfonts/" .. default_sf) then
	local data = love.filesystem.read("files/" .. default_sf)
	if system == "Others" then
		love.filesystem.write("soundfonts/" .. default_sf, data)
	elseif system == "ArkOS" then
		local file = io.open(love.filesystem.getSaveDirectory().."//soundfonts/"  .. default_sf, "w+")
		file:write(data)
		file:close()
	end
	data = nil
end

-- do the same with the library itself since love
-- can't read libraries from the project folder

local libfile

if platform == "Linux" then
	libfile = "libfluidsynth.so"
elseif platform == "Windows" then
	libfile = "libfluidsynth-3.dll"
elseif platform == "OS X" then
	libfile = "libfluidsynth-3.dylib"
end

if not file_exists(libfile) then
	print(libfile .. " doesn't exist in save directory. Copying...")

	if platform == "Windows" then
		local files = love.filesystem.getDirectoryItems("files")
		for _, file in ipairs(files) do
			local ext = file:match("^.+%.(.+)$")
			if ext == "dll" then
				print("=> Copying " .. file)
				local libdata = love.filesystem.read("files/" .. file)
				love.filesystem.write(file, libdata)
				libdata = nil
			end
		end
	else
		local libdata = love.filesystem.read("files/" .. libfile)
		-- writing file for OS X and Linux
		love.filesystem.write(libfile, libdata)
		-- additional code for ArkOS since only LUA I/O works for it
		if system == "ArkOS" then
			local file = io.open(love.filesystem.getSaveDirectory().."//"  .. libfile, "w+")
			file:write(libdata)
			file:close()
		end
		libdata = nil
	end
end



local FluidSynth = require("fluidsynth")

local synth
local notes = {60, 62, 64, 65, 67, 69, 71, 72} -- C Major Scale
local currentNote = 1
local bpm = 120
local timer = 0

function love.load()

	local save_path = love.filesystem.getSaveDirectory()

    -- Create a new Fluidsynth instance
    synth = FluidSynth:new(save_path .. "/soundfonts/example.sf2")
end

function love.update(dt)
    local secondsPerBeat = 60 / bpm
    timer = timer + dt

    if timer >= secondsPerBeat then
        timer = timer - secondsPerBeat

        -- Play a note from the scale
        synth:play(notes[currentNote], 100)
        if currentNote > 1 then
            synth:stop(notes[currentNote - 1])
        end

        currentNote = currentNote % #notes + 1
    end
end

function love.quit()
    synth:destroy() -- Clean up Fluidsynth resources
end
