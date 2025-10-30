using Plots

# Coordinates
coords = [
    14 13;
    16 1;
    3 5;
    16 1;
    11 2;
    2 14;
    5 12;
    10 6;
    17 17;
    17 1;
    3 8;
    17 7;
    17 14;
    9 14;
    14 4;
    3 9;
    8 8;
    16 11;
    14 13;
    17 13;
    12 5;
    1 12;
    15 12;
    16 3;
    12 3;
    13 9;
    13 17;
    7 6;
    12 10;
    3 4
]

x = coords[:, 1]
y = coords[:, 2]

# Create scatter plot
p = plot(x, y, seriestype = :scatter, legend = false,
         title = "Network Nodes",
         xlabel = "X coordinate", ylabel = "Y coordinate",
         markersize = 6)

# Add improved annotations with small offsets
offsets = [(0.3,0.3), (-0.3,0.3), (0.3,-0.3), (-0.3,-0.3)]  # alternating positions
for i in 1:length(x)
    dx, dy = offsets[(i % length(offsets)) + 1]  # cycle through offsets
    annotate!(p, x[i] + dx, y[i] + dy, text(string(i), :red, 8))
end

display(p)
