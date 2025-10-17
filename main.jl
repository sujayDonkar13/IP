# IMPORTANT! Your names, surnames, student IDs
# Include here packages
using DelimitedFiles, Printf
# Include here other scripts if needed, e.g., include("myfunctions.jl")
include("evaluator.jl")

#### Assignment 1a
# Initialize parameters
max_lines = 6
max_stops = 20
tp = 5 

# Initialize network
coords = readdlm("Coords.txt")
OD = readdlm("Demand.txt")
network = readdlm("Network.txt")

lineplan = [
    1  27  9  20  18  19  14  7  16  3  30  11  22  6  25  24  21  8  28  0;
    23 26 12  4   2   5  15 10  18 13  19 14   7 17  29   1  27  9  20   0;
    30  3 16  6  22  11  28  8  21 24  15 12  18 23  19  20  13 14   0   0;
    17 29 18 19  14   7  22 11  30  6  16  3  28  8  21  25   2  4  12   0;
    26 23  1 27   9  13  20 18  12 15  10 24   5  2   4  12  25 21   8   0;
    19 14  7 22  11  30  16  6  17 29   1 27  23 26  12   4   2  5  15   0
]

n = size(network, 1)

# Step 1: Check feasibility of the line plan 
feasible, served_stops, problematic_stops = check_feasibility(network, lineplan, OD, max_lines, max_stops)
if !feasible
    println("Warning: Line plan is not feasible. Check feasibliity conditions.")
end

# Step 2: Calculate total passenger travel time based on the shortest paths given the lineplan and the transfer penalty tp
shortest, lineinfo, directlink, path = shortest_paths(network, lineplan, tp)

if !feasible
    println("Warning: Line plan is not feasible. Total Travel Time (TTT) and Average Travel Time (AVT) are set to Infinity")
    TTT = Inf
    AVT = Inf
else
    # Line plan is feasible i.e, there are no problematic stops.
    # Compute the total passenger travel time for the served stops with the aggregate OD demand
    TTT = sum(shortest[served_stops, served_stops] .* OD[served_stops, served_stops])
    AVT = TTT/sum(OD)
    println("Total passenger travel time (TTT): ", @sprintf("%.2f", TTT))
    println("Average passenger travel time (AVT): ", @sprintf("%.2f", AVT))
end

# Example usage of helper function to reconstruct the shortest path, transfers, ridetime and lines taken 
origin = 9
destination = 5
stopsvisited, linestaken, ridetime = reconstruct_shortestroute(origin, destination, path, lineinfo, directlink)
total_shortest = shortest[origin, destination]
total_ridetime = sum(ridetime)
transfer_penalty_total = tp * (length(linestaken) - 1)

println()
println("--- Example ----")
println("Example OD pair: From $origin To $destination")
println("Stops visited: $stopsvisited")
println("Lines taken: $linestaken", " → Total transfer penalty: $transfer_penalty_total")
println("Ridetime per line: $ridetime", " → Total ridetime: $total_ridetime")
println("Total shortest path time (ridetime + transfers): $total_shortest")

# Step 3: Define your KPI for direct travelers and evaluate

# Step 4: Define your KPI for fairness and evaluate
