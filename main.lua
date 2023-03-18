Slab = require("Slab")
require("stuff")

function love.load(args)
    key1 = "z"
    key2 = "x"
    max_taps = 64

    enable_consistency_bars = true
    enable_all_keys = true
    enable_autotap = false
    enable_reset_with_r = true

    open_hexagon_font = love.graphics.newFont("assets/OpenSquare-Regular.ttf", 21)

    Slab.Initialize(args)
    set_slab_style()

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
        tap(key)
    end

    if key == "escape" or enable_reset_with_r and key == "r" then
        reset()
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    love.keypressed("mouse" .. button, 69, false)
end

function love.update(dt)
    autotapper = autotapper + 1

    if enable_autotap and autotapper % 7 == 0 then
        love.keypressed("auto" .. autotapper, 727, false)
    end

    Slab.Update(dt)
    slab_settings_menu()
end

function love.draw()
    if started then
        elapsed_time = love.timer.getTime() - start_time
    end

    if mistake then
        love.graphics.setColor(1, 0, 0, 1)
    else
        love.graphics.setColor(1, 1, 1, 1)        
    end

    local width = love.graphics.getWidth()
    love.graphics.printf(string.format("%d taps in %.3f seconds", #timing_points, elapsed_time), 0, 0, width, "center")
    love.graphics.printf(string.format("\n%.2f BPM", get_bpm()), 0, 0, width, "center")
    love.graphics.printf(string.format("\n\nUnstable Rate: %.2f  [%.2f]", get_ur(), precise_ur()), 0, 0, width, "center")

    if enable_consistency_bars then 
        draw_consistency_bars() 
    end

    Slab.Draw()
end



