include("evaluator.jl")

# Function for plotting the line plan (Adrian)
function plot_lineplan(coords, lineplan, zoom)
    plot_network(coords,lineplan,zoom)
    println("Visualizing each line individually with background network...")


end 


function plot_network(coords, lineplan,zoom)
    # Coordinates of stops
    x_coords = zoom*coords[:, 1]
    y_coords = zoom*coords[:, 2]
    num_lines = size(lineplan, 1)

    # Define color palette
    colors = palette(:Set1, num_lines)

    # === Plot each line individually ===
    for line_idx in 1:num_lines
        stops = lineplan[line_idx, lineplan[line_idx, :] .> 0]
        line_x = x_coords[stops]
        line_y = y_coords[stops]

        p = plot(
            title = "Line $line_idx Route (with background network)",
            xlabel = "X coordinate", ylabel = "Y coordinate",
            legend = false, aspect_ratio = :equal
        )

        # Add full network background first
        plot_background_network!(p, network, x_coords, y_coords)

        # Add the current line
        plot!(p, line_x, line_y,
            lw = 2.5,
            color = colors[line_idx],
            marker = :circle,
            markersize = 6,
            alpha = 0.9,
            label = ""
        )

        # Annotate stops (with random offset)
        for (i, stop) in enumerate(stops)
            x_off, y_off = offset_label(line_x[i], line_y[i])
            annotate!(p, x_off, y_off, text(string(stop), :black, 7))
        end

        display(p)
    end

    println(" All six lines plotted individually with background network.")

    # === Combined overview plot ===
    p_all = plot(
        title = "Full Network Line Plan Overview",
        xlabel = "X coordinate", ylabel = "Y coordinate",
        legend = false, aspect_ratio = :equal
    )

    # Add full network background
    plot_background_network!(p_all, network, x_coords, y_coords)

    # Overlay all six lines
    for line_idx in 1:num_lines
        stops = lineplan[line_idx, lineplan[line_idx, :] .> 0]
        line_x = x_coords[stops]
        line_y = y_coords[stops]
        plot!(p_all, line_x, line_y,
            lw = 2, color = colors[line_idx], label = "Line $line_idx", alpha = 0.9)
    end

    # Add all stop markers
    scatter!(p_all, x_coords, y_coords, color = :gray, markersize = 4, label = "")

    # Annotate all stop numbers
    for i in 1:length(x_coords)
        x_off, y_off = offset_label(x_coords[i], y_coords[i])
        annotate!(p_all, x_off, y_off, text(string(i), :black, 6))
    end

    display(p_all)
    println(" Combined network overview displayed.")
    end


# Function to slightly offset label positions to reduce overlap
function offset_label(x, y, magnitude=0.3)
    angle = 2π * rand()
    return x + magnitude*cos(angle), y + magnitude*sin(angle)
end

# Function to draw the full network (gray lines)
function plot_background_network!(p, network, x_coords, y_coords)
    n = size(network, 1)
    for i in 1:n, j in 1:n
        if network[i, j] > 0 && isfinite(network[i, j])
            plot!(p, [x_coords[i], x_coords[j]], [y_coords[i], y_coords[j]],
                  color = :lightgray, lw = 0.5, label = "")
        end
    end
end


# Fairness Approach Key Performance Indicator
# This section contains the code used to calculate the fairness approach KPI,
# based on section #### of the main document pdf.

# Option 1. Specify source and section in main document
function fairness_index(shortest_lineplan, network, OD)
    n = size(OD, 1)
    best_shortest, _ = floyd_warshall(network)

    ratios = Float64[]
    for i in 1:n, j in 1:n
        if i != j && OD[i,j] > 0 && isfinite(shortest_lineplan[i,j]) && isfinite(best_shortest[i,j])
            push!(ratios, shortest_lineplan[i,j] / best_shortest[i,j])
        end
    end

    p90 = quantile(ratios, 0.9)
    mean_ratio = mean(ratios)
    return p90, mean_ratio, ratios
end

# Option 2. Specify source and section in main document
function gini_index(values)
    n = length(values)
    mean_val = mean(values)
    G = sum(abs(values[i] - values[j]) for i in 1:n, j in 1:n) / (2n^2 * mean_val)
    return G
end

# Direct Travelers Approach Key Performance Indicator 
# This section contains the code used to calculate the direct travelers approach KPI,
# based on section #### of the main document pdf.

function direct_travelers_share(OD, lineplan)
    n = size(OD, 1)
    total_demand = sum(OD)
    direct_demand = 0.0

    # For each pair (i,j), check if they are on at least one common line
    for i in 1:n, j in 1:n
        if i == j || OD[i, j] == 0
            continue
        end
        for line in eachrow(lineplan)
            stops = line[line .> 0]
            if (i in stops) && (j in stops)
                direct_demand += OD[i, j]
                break  # one line is enough
            end
        end
    end

    return direct_demand / total_demand
end
