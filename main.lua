Slab = require("Slab")
require("stuff")

function love.load(args)
    key1 = "kp1"
    key2 = "kp5"
    max_taps = 64

    enable_consistency_bars = true
    autotap = false
    
    open_hexagon_font = love.graphics.newFont("assets/OpenSquare-Regular.ttf", 22)

    Slab.Initialize(args)
    Slab.GetStyle().FontSize = 30 -- doesn't work?
    Slab.GetStyle().WindowBackgroundColor = {0, 0, 0, 0}
    Slab.GetStyle().ButtonColor = {1, 1, 1, 1}
    Slab.GetStyle().CheckBoxSelectedColor = {0, 0, 0, 1}
    Slab.GetStyle().TextColor = {1, 1, 1, 1}
    Slab.GetStyle().InputBgColor = {0.1, 0.1, 0.1, 1}
    Slab.GetStyle().InputEditBgColor = {0.2, 0.2, 0.2, 1}
    Slab.GetStyle().InputSelectColor = {0, 0.75, 1, 0.5}
    Slab.GetStyle().CheckBoxRounding = 0
    Slab.GetStyle().InputBgRounding = 0

    function reset()
        started = false
        stopped = false
        timing_points = {}
        diffs = {}
        heights = {}
        start_time = 0
        elapsed_time = 0
        oldkey = ""
        autotapper = 0
        mistake = false
    end
    reset()
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

        mistake = oldkey == key

        oldkey = key
    end

    if #timing_points >= max_taps then
        started = false
        stopped = true
    end

    if key == "r" then
        reset()
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    love.keypressed("mouse" .. button, 69, false)
end

function love.update(dt)
    autotapper = autotapper + 1

    if autotap and autotapper % 7 == 0 then
        love.keypressed("auto", 727, false)
    end

    Slab.Update(dt)
    slab_settings_menu()
end

function love.draw()
    local width = love.graphics.getWidth()

    if started then
        elapsed_time = love.timer.getTime() - start_time
    end

    if mistake then
        love.graphics.setColor(1, 0, 0, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)        
    end

    love.graphics.setFont(open_hexagon_font)
    love.graphics.printf(string.format("%d taps in %.3f seconds", #timing_points, elapsed_time), 0, 0, width, "center")
    love.graphics.printf(string.format("\n%.2f BPM", get_bpm()), 0, 0, width, "center")
    love.graphics.printf(string.format("\n\nUnstable Rate: %.2f  [%.2f]", get_ur(), precise_ur()), 0, 0, width, "center")

    if enable_consistency_bars then 
        draw_consistency_bars() 
    end

    Slab.Draw()
end



