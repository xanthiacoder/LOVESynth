local FluidSynth = require("fluidsynth")

local synth
local notes = {60, 62, 64, 65, 67, 69, 71, 72} -- C Major Scale
local currentNote = 1
local bpm = 120
local timer = 0

function love.load()
    -- Create a new Fluidsynth instance
    synth = FluidSynth:new("example.sf2")
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
