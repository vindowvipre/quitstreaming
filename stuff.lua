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
        NoDrag = true,
    }) then
        max_taps = Slab.GetInputNumber()
    end

    if Slab.CheckBox(enable_consistency_bars, "Show consistency bars", {
        Tooltip = "Visually show the time between the start of each tap",
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

    if Slab.CheckBox(enable_all_keys, "Allow every key", {
        Tooltip = "Push your limits",
        Size = 22,
        Disabled = true -- todo
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

	Slab.EndWindow()
end

function tap(key)
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

function draw_consistency_bars()
    local width = love.graphics.getWidth()

    if enable_key_indicator then
        width = width - 200
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

function draw_key_indicator()
    local x1 = love.graphics.getWidth() - 185
    local x2 = love.graphics.getWidth() - 95
    local y = love.graphics.getHeight() - 90
    local size = 60

    love.graphics.rectangle("line",  x1, y, size, size)
    love.graphics.rectangle("line",  x2, y, size, size)

    if love.keyboard.isDown(key1) then
        love.graphics.rectangle("fill",  x1, y, size, size)
    end
    if love.keyboard.isDown(key2) then
        love.graphics.rectangle("fill",  x2, y, size, size)
    end

    love.graphics.printf(key1, x1, y + 16, size, "center")
    love.graphics.printf(key2, x2, y + 16, size, "center")
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

