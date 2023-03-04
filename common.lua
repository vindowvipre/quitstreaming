function get_bpm()
    if #timing_points == 0 then return 0 end
    -- simply dividing taps by time will overestimate bpm at the start
    -- so this emulates adding the "finger-windup" time for the first press
    -- multiply CPS by 15 to get BPM

    --return taps/(time * (taps + 1)/taps) * 15
    return (#timing_points - 1)/(elapsed_time) * 15
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

