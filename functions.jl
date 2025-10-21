include("evaluator.jl")

# Function for plotting the line plan (Adrian)
function plot_lineplan(coords, lineplan)
    num_lines = size(lineplan, 1)
    colors = distinguishable_colors(num_lines)
    plt = scatter(coords[:,1], coords[:,2], markersize=5, label="Stops", legend=:topright, 
                    title="Line Plan Visualization", xlabel="X Coordinate", 
                    ylabel="Y Coordinate")
    
    for line_idx in 1:num_lines
        line_stops = lineplan[line_idx, :]
        line_stops = filter(x -> x != 0, line_stops)  # Remove zeros (non-stops)
        line_coords = coords[line_stops .+ 1, :]  # +1 for 1-based indexing
        plot!(plt, line_coords[:,1], line_coords[:,2], lw=2, color=colors[line_idx], 
                    label="Line $line_idx")
    end
    
    display(plt)
end 
