-- i don't really understand the style documentation, this is the only way i could get it to work
function set_slab_style()
    Slab.GetStyle().Font = open_hexagon_font
    Slab.GetStyle().WindowBackgroundColor = {0, 0, 0, 1}
    Slab.GetStyle().ButtonColor = {1, 1, 1, 1}
    Slab.GetStyle().CheckBoxSelectedColor = {0, 0, 0, 1}
    Slab.GetStyle().TextColor = {1, 1, 1, 1}
    Slab.GetStyle().InputBgColor = {1, 1, 1, 1}
    Slab.GetStyle().InputEditBgColor = {0.8, 0.8, 0.8, 1}
    Slab.GetStyle().InputSelectColor = {0, 0.75, 1, 0.5}
    Slab.GetStyle().CheckBoxRounding = 0
    Slab.GetStyle().InputBgRounding = 0
end

function slab_settings_menu()
    Slab.BeginWindow('settings_window', {
        X = 0,
        Y = 0,
        AllowMove = false,
        AllowResize = false,
        NoOutline = true
    })

    Slab.Text("Number of taps")
    if Slab.Input('Number of taps', {
        Text = tostring(max_taps), 
        TextColor = {0, 0, 0, 1},
        NumbersOnly = true,
        MinNumber = 2,
        Step = 4,
        W = 160,
        H = 21,
        NoDrag = true
    }) then
        max_taps = Slab.GetInputNumber()
    end

    if Slab.CheckBox(enable_consistency_bars, "Show consistency bars", {
        Tooltip = "Show the time between each tap's start",
        Size = 22
    }) then
        enable_consistency_bars = not enable_consistency_bars
    end

    if Slab.CheckBox(enable_key_indicator, "Show key indicator", {
        Tooltip = "See history of pressed keys",
        Size = 22
    }) then
        enable_key_indicator = not enable_key_indicator
    end

    if Slab.CheckBox(enable_mouse_buttons, "Allow mouse buttons", {
        Tooltip = "Mouse-only is the only fun way to play osu",
        Size = 22
    }) then
        enable_mouse_buttons = not enable_mouse_buttons
    end

    if Slab.CheckBox(enable_all_keys, "Allow every key", {
        Tooltip = "Push your limits",
        Size = 22,
    }) then
        enable_all_keys = not enable_all_keys
    end

	if Slab.CheckBox(enable_autotap, "Auto-tap", {
        Tooltip = "Cheater",
        Size = 22
    }) then
        enable_autotap = not enable_autotap
    end

    if Slab.CheckBox(enable_reset_with_r, "Reset with R key", {
        Tooltip = "There's at least 1 fucker who uses R as one of their keys (escape also works)",
        Size = 22
    }) then
        enable_reset_with_r = not enable_reset_with_r
    end

    Slab.Text("Scroll Speed")
    if Slab.Input('Scroll Speed', {
        Text = tostring(scrolling_speed), 
        TextColor = {0, 0, 0, 1},
        NumbersOnly = true,
        MinNumber = 30,
        MaxNumber = 3000,
        Step = 20,
        W = 160,
        H = 21,
        NoDrag = true
    }) then
        scrolling_speed = Slab.GetInputNumber()
    end

	Slab.EndWindow()
end

function tap(key)
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

        if #timing_points >= max_taps then
            started = false
            stopped = true
        end  
    end

      
end

function draw_consistency_bars()
    local width = love.graphics.getWidth()

    if enable_key_indicator then
        width = width - 150
    end

    local max_height = 0 

    local iterations = math.ceil(width/50)

    for i = 1, iterations do
        local h = diffs[#diffs - i + 1] or 0
        heights[i] = h
        max_height = math.max(max_height, h)
    end

    for i = 1, iterations do
        local h = heights[i]/max_height
        h = h * love.graphics.getHeight() * 0.5
        love.graphics.rectangle("fill", width - i * 50, love.graphics.getHeight() - h, 30, h)
    end
end

function update_key_history()
    if key1_state ~= love.keyboard.isDown(key1) then 
        key1_history[#key1_history + 1] = elapsed_time
    end
    if key2_state ~= love.keyboard.isDown(key2) then 
        key2_history[#key2_history + 1] = elapsed_time
    end
    key1_state = love.keyboard.isDown(key1)
    key2_state = love.keyboard.isDown(key2)
end

function draw_key_indicator()
    local x1 = love.graphics.getWidth() - 150
    local x2 = love.graphics.getWidth() - 75
    local y = love.graphics.getHeight() - 75

    love.graphics.rectangle("line",  x1, y, square_size, square_size)
    love.graphics.rectangle("line",  x2, y, square_size, square_size)

    if love.keyboard.isDown(key1) then
        love.graphics.rectangle("fill",  x1, y, square_size, square_size)
    end
    if love.keyboard.isDown(key2) then
        love.graphics.rectangle("fill",  x2, y, square_size, square_size)
    end

    love.graphics.printf(key1, x1, y + 16, square_size, "center")
    love.graphics.printf(key2, x2, y + 16, square_size, "center")

    draw_key_history(key1_history, x1, y, square_size)
    draw_key_history(key2_history, x2, y, square_size)
end

-- rewrite this to be less spaghetti?
function draw_key_history(key_history, x, base_y, width)
    local r, g, b = love.graphics.getColor()
    love.graphics.setColor(r, g, b, 0.5)

    local height = 0
    local time_offset = 0

    if #key_history % 2 == 1 then
        height = elapsed_time - key_history[#key_history]
        height = height * scrolling_speed
        love.graphics.rectangle("fill", x, base_y - height, width, height)
    end
    
    local index = 0
    local num_presses = math.floor(#key_history * 0.5)
    for i = 1, num_presses do
        local last_release = num_presses * 2

        height = (key_history[last_release - index] or 0) - (key_history[last_release - index - 1] or 0)
        time_offset = elapsed_time - (key_history[last_release - index] or 0)

        index = index + 2

        height = height * scrolling_speed
        time_offset = time_offset * scrolling_speed

        if base_y - time_offset < 0 then
            break
        end

        love.graphics.rectangle("fill", x, base_y - (height + time_offset), width, height)
    end
end

-- is ui stuff possible to not be spaghetti
function draw_key_buttons()
    local x1 = love.graphics.getWidth()/2 - 80
    local x2 = x1 + 100

    -- below the text
    local y = love.graphics.getHeight()/15 + 175

    love.graphics.rectangle("line",  x1, y, square_size, square_size)
    love.graphics.rectangle("line",  x2, y, square_size, square_size)
    local mouse_x, mouse_y = love.mouse.getPosition()
    
    local mid_x1 = x1 + square_size/2
    local mid_x2 = x2 + square_size/2
    local mid_y = y + square_size/2

    -- sdf-type square distance to the middle of the button, instead of checking all bounds
    local dist = math.max(math.abs(mouse_x - mid_x1), math.abs(mouse_y - mid_y))

    local r, g, b, a = love.graphics.getColor()

    -- when mouse is hovered
    if dist < square_size/2 then
        if love.mouse.isDown(1) then
            selecting_key = 1
        else
            love.graphics.setColor(r, g, b, 0.3)
        end

        love.graphics.rectangle("fill",  x1, y, square_size, square_size)
    end

    dist = math.max(math.abs(mouse_x - mid_x2), math.abs(mouse_y - mid_y))
    if dist < square_size/2 then
        if love.mouse.isDown(1) then
            selecting_key = 2
        else
            love.graphics.setColor(r, g, b, 0.3)
        end

        love.graphics.rectangle("fill",  x2, y, square_size, square_size)
    end

    love.graphics.setColor(r, g, b, a)

    if selecting_key ~= 1 then
        love.graphics.printf(key1, x1, y + 16, square_size, "center")
    end
    if selecting_key ~= 2 then
        love.graphics.printf(key2, x2, y + 16, square_size, "center")
    end
end


function get_bpm()
    if #timing_points == 0 then return 0 end
    -- simply dividing taps by time will overestimate bpm at the start
    -- one way is to add the "finger-windup" time for the first press
    -- but this method just ignores the first press entirely
    -- multiply CPS by 15 to get BPM

    --return taps/(time * (taps + 1)/taps) * 15
    --return (#timing_points - 1)/(elapsed_time) * 15
    return (#timing_points - 1)/timing_points[#timing_points] * 15
end

-- ysasv2 method
function get_ur()
    if #timing_points < 2 then return 0 end

    local avg_press = timing_points[#timing_points]/(#timing_points - 1)

    local std = 0

    for i = 1, #diffs do
        std = std + (diffs[i] - avg_press)^2
    end

    std = math.sqrt(std/#diffs)

    return (std * 10000) -- osu unstable rate is in milliseconds * 10
end

-- line of best fit https://developer.ibm.com/articles/linear-regression-from-scratch/
function linear_regression(t)
    local avg_x = (#t + 1)/2
    local avg_y = 0
    local sum_top = 0
    local sum_bottom = 0

    for i = 1, #t do
        avg_y = avg_y + t[i]
    end
    avg_y = avg_y/#t

    for i = 1, #t do
        sum_top = sum_top + (i - avg_x) * (t[i] - avg_y)
        sum_bottom = sum_bottom + (i - avg_x)^2
    end

    local slope = sum_top/sum_bottom
    local y_intercept = avg_y - slope * avg_x
    return slope, y_intercept
end

function precise_ur()
    if #timing_points < 2 then return 0 end

    local m, b = linear_regression(timing_points)
    local function f(x)
        return m * x + b
    end
    
    local standard_deviation = 0

    for i = 1, #timing_points do
        standard_deviation = standard_deviation + (timing_points[i] - f(i))^2
    end

    standard_deviation = math.sqrt(standard_deviation/(#timing_points - 1))

    return (standard_deviation * 10000)
end

