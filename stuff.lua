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
    }) then
        max_taps = Slab.GetInputNumber()
    end

    if Slab.CheckBox(enable_consistency_bars, "Show consistency bars", {
        Tooltip = "Visually show the time between the start of each tap",
        Size = 22
    }) then
        enable_consistency_bars = not enable_consistency_bars
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

	Slab.EndWindow()
end

function draw_consistency_bars()
    local max_height = 0 

    local iterations = math.ceil(love.graphics.getWidth()/50)

    for i = 1, iterations do
        local h = diffs[#diffs - i + 1] or 0
        heights[i] = h
        max_height = math.max(max_height, h)
    end

    for i = 1, iterations do
        local h = heights[i]/max_height
        h = h * love.graphics.getHeight() * 0.5
        love.graphics.rectangle("fill", love.graphics.getWidth() - i * 50, love.graphics.getHeight() - h, 30, h)
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

