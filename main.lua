require("common")

function love.load()
    key1 = "kp1"
    key2 = "kp5"
    max_taps = 64

    autotap = false

    started = false
    stopped = false
    timing_points = {}
    diffs = {}
    heights = {}
    start_time = 0
    elapsed_time = 0
    autotapper = 0
    oldkey = ""
    font = love.graphics.newFont("assets/OpenSquare-Regular.ttf", 22)

    love.graphics.setFont(font)
end

function love.keypressed(key, scancode, isrepeat)
    if not started and not stopped then
        start_time = love.timer.getTime()
        started = true
    end

    if started then
        timing_points[#timing_points + 1] = love.timer.getTime() - start_time
        if #timing_points > 1 then
            diffs[#diffs + 1] = timing_points[#timing_points] - timing_points[#timing_points - 1]
        end

        if oldkey == key then
            love.graphics.setColor(1, 0, 0, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        oldkey = key
    end

    if #timing_points >= max_taps then
        started = false
        stopped = true
    end

    if key == "r" then
        love.load()
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    love.keypressed("mouse" .. button, 69, false)
end

function love.update(ft)
    autotapper = autotapper + 1

    if autotap and autotapper % 7 == 0 then
        love.keypressed("auto", 727, false)
    end
end

function love.draw()
    local width = love.graphics.getWidth()

    if started then
        elapsed_time = love.timer.getTime() - start_time
    end

    love.graphics.printf(string.format("%d taps in %.2f seconds", #timing_points, elapsed_time), 0, 0, width, "center")
    love.graphics.printf(string.format("\n%.2f BPM", get_bpm()), 0, 0, width, "center")
    love.graphics.printf(string.format("\n\nUnstable Rate: %.2f  [%.2f]", get_ur(), precise_ur()), 0, 0, width, "center")


    local max_height = 0

    local iterations = math.ceil(width/50)

    for i = 1, iterations do
        local h = diffs[#diffs - i + 1] or 0
        heights[i] = h
        max_height = math.max(max_height, h)
    end

    for i = 1, iterations do
        local h = heights[i]/max_height
        h = h * 300
        love.graphics.rectangle("fill", width - i * 50, love.graphics.getHeight() - h, 30, h)
    end
end



