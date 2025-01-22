local FluidSynth = require("fluidsynth")

local synth
local grid = {}
local cellWidth = 40
local cellHeight = 20
local numKeys = 88 -- Piano keys (y-axis)
local numSteps = 16 -- Time steps (x-axis)
local bpm = 120
local timer = 0
local currentStep = 1
local noteStart = 21 -- MIDI note for A0 (lowest key)
local playingNotes = {}
local paused = false -- New variable to track play/pause state

function love.load()
    -- Initialize the grid
    for i = 1, numKeys do
        grid[i] = {}
        for j = 1, numSteps do
            grid[i][j] = false
        end
    end

    -- Load Fluidsynth and SoundFont
    synth = FluidSynth:new("example.sf2") -- Replace with your SoundFont
end

function love.update(dt)
    if not paused then
        local secondsPerBeat = 60 / bpm
        local secondsPerStep = secondsPerBeat / numSteps
        timer = timer + dt

        if timer >= secondsPerStep then
            timer = timer - secondsPerStep

            -- Stop all currently playing notes
            for _, note in ipairs(playingNotes) do
                synth:stop(note)
            end
            playingNotes = {}

            -- Move to the next step
            currentStep = (currentStep % numSteps) + 1

            -- Play all active notes in the current step
            for i = 1, numKeys do
                if grid[i][currentStep] then
                    local note = noteStart + i - 1
                    synth:play(note, 100)
                    table.insert(playingNotes, note)
                end
            end
        end
    end
end

function love.draw()
    -- Draw the piano roll grid
    for i = 1, numKeys do
        for j = 1, numSteps do
            local x = (j - 1) * cellWidth
            local y = (i - 1) * cellHeight

            -- Draw cell background
            if grid[i][j] then
                love.graphics.setColor(0, 1, 0) -- Active cell (green)
            else
                love.graphics.setColor(1, 1, 1) -- Inactive cell (white)
            end
            love.graphics.rectangle("fill", x, y, cellWidth, cellHeight)

            -- Draw cell border
            love.graphics.setColor(0, 0, 0) -- Black border
            love.graphics.rectangle("line", x, y, cellWidth, cellHeight)
        end
    end

    -- Highlight current step
    if not paused then
        love.graphics.setColor(1, 0, 0, 0.5) -- Red highlight for active step
        love.graphics.rectangle("fill", (currentStep - 1) * cellWidth, 0, cellWidth, numKeys * cellHeight)
    end

    -- Display play/pause status
    love.graphics.setColor(0, 0, 0) -- Black text
    love.graphics.print(paused and "Paused" or "Playing", 10, numKeys * cellHeight + 10)
end

function love.mousepressed(x, y, button)
    if button == 1 then
        -- Determine which cell was clicked
        local j = math.floor(x / cellWidth) + 1
        local i = math.floor(y / cellHeight) + 1

        if i >= 1 and i <= numKeys and j >= 1 and j <= numSteps then
            -- Toggle the cell
            grid[i][j] = not grid[i][j]
        end
    end
end

function love.keypressed(key)
    if key == "space" then
        paused = not paused -- Toggle play/pause
    elseif key == "up" then
        bpm = bpm + 5 -- Increase BPM
    elseif key == "down" then
        bpm = bpm - 5 -- Decrease BPM
    end
end

function love.quit()
    synth:destroy() -- Clean up Fluidsynth resources
end
