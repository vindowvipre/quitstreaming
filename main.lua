Slab = require("Slab")
require("stuff")

function love.load(args)
    key1 = "a"
    key2 = "s"
    max_taps = 64

    enable_consistency_bars = true
    enable_key_indicator = true
    enable_mouse_buttons = false
    enable_all_keys = false
    enable_autotap = false
    enable_reset_with_r = true
    scrolling_speed = 600

    open_hexagon_font = love.graphics.newFont("assets/OpenSquare-Regular.ttf", 24)
    square_size = 60

    Slab.Initialize(args)
    set_slab_style()

    love.graphics.setLineWidth(3)

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
        key1_history = {}
        key2_history = {}
        key1_state = false
        key2_state = false
    end
    reset()
end

function love.keypressed(key, scancode, isrepeat)
    if selecting_key == 1 then
        key1 = key
        selecting_key = 0
        key = nil
    elseif selecting_key == 2 then
        key2 = key
        selecting_key = 0
        key = nil
    end


    if key == key1 or key == key2 or enable_all_keys then
        tap(key)
    end

    if key == "escape" or enable_reset_with_r and key == "r" then
        reset()
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if enable_mouse_buttons then
        tap("mouse" .. button)
    end
end

function love.update(dt)
    autotapper = autotapper - dt

    if enable_autotap and autotapper < 0 then
        love.keypressed("auto" .. autotapper, 727, false)
        autotapper = 0.05
    end

    if started then
        update_key_history()
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
    local text_height = love.graphics.getHeight()/15
    love.graphics.printf(string.format("%d taps in %.3f seconds", #timing_points, elapsed_time), 0, text_height, width, "center")
    love.graphics.printf(string.format("\n%.2f BPM", get_bpm()), 0, text_height, width, "center")
    love.graphics.printf(string.format("\n\nUnstable Rate: %.2f  [%.2f]", get_ur(), precise_ur()), 0, text_height, width, "center")

    draw_key_buttons()
    if enable_consistency_bars then 
        draw_consistency_bars() 
    end
    if enable_key_indicator then
        draw_key_indicator()
    end 
    
    Slab.Draw()
end



