function directlinknetworkinit(network, lineplan)
    nbnodes = size(network, 1)
    nblines, maxnode = size(lineplan)
    
    lineinfo   = zeros(Int, nbnodes, nbnodes)
    directlink = fill(Inf, nbnodes, nbnodes)

    for j in 1:nblines
        # check if the line is a loop
        startnode = lineplan[j, 1]
        startid   = findall(x -> x == startnode, lineplan[j, :])

        if length(startid) <= 1
            # Line is not a loop
            for k in 1:maxnode-1
                originid = lineplan[j, k]
                for l in k+1:maxnode
                    destinationid = lineplan[j, l]
                    if originid == 0 || destinationid == 0
                        break
                    end
                    ridedist = 0.0
                    for p in k:l-1
                        ridedist += network[lineplan[j, p], lineplan[j, p+1]]
                    end
                    directlink[originid, originid] = 0.0
                    lineinfo[originid, originid]   = 0
                    if ridedist < directlink[originid, destinationid]
                        directlink[originid, destinationid] = ridedist
                        lineinfo[originid, destinationid]   = j
                    end
                    if ridedist < directlink[destinationid, originid]
                        directlink[destinationid, originid] = ridedist
                        lineinfo[destinationid, originid]   = j
                    end
                end
            end
        else
            # Line is a loop
            linelength = 0.0
            for i in 1:maxnode-1
                if lineplan[j, i] == 0 || lineplan[j, i+1] == 0
                    break
                end
                linelength += network[lineplan[j, i], lineplan[j, i+1]]
            end
            for k in 1:maxnode-1
                originid = lineplan[j, k]
                if originid == 0
                    break
                end
                for l in k+1:maxnode
                    destinationid = lineplan[j, l]
                    if destinationid == 0
                        break
                    end
                    ridedist = 0.0
                    for p in k:l-1
                        ridedist += network[lineplan[j, p], lineplan[j, p+1]]
                    end
                    directlink[originid, originid] = 0.0
                    lineinfo[originid, originid]   = 0
                    if ridedist < directlink[originid, destinationid]
                        directlink[originid, destinationid] = ridedist
                        lineinfo[originid, destinationid]   = j
                    end
                    if linelength - ridedist < directlink[destinationid, originid]
                        directlink[destinationid, originid] = linelength - ridedist
                        lineinfo[destinationid, originid]   = j
                    end
                end
            end
        end
    end

    return directlink, lineinfo
end

function floyd_warshall(Dist::Matrix{Float64})
    n = size(Dist, 1)
    shortest = copy(Dist)
    prevD = copy(shortest)
    path = zeros(Int, n, n)  # store intermediate node
    
    for k in 1:n
        for i in 1:n
            for j in 1:n
                if isfinite(shortest[i,k]) && isfinite(shortest[k,j])
                    if shortest[i,j] > shortest[i,k] + shortest[k,j]
                        shortest[i,j] = shortest[i,k] + shortest[k,j]
                        path[i,j] = k
                    end
                end
            end
        end
    end
    
    return shortest, path
end

function shortest_paths(network, lineplan, tp)
    # Step 1: Build direct link network
    directlink, lineinfo = directlinknetworkinit(network, lineplan)

    # Step 2: Add transfer penalty to all non-diagonal entries
    n = size(directlink, 1)
    directlink_with_tp = copy(directlink)
    for i in 1:n, j in 1:n
        if i != j && isfinite(directlink[i,j])
            directlink_with_tp[i,j] += tp
        end
    end

    # Step 3: Compute all-pairs shortest paths using Floyd-Warshall Algorithm
    shortest, path = floyd_warshall(directlink_with_tp)
    
    # Step 4: Deduce one transfer penalty per OD (to correct for first boarding)
    for i in 1:n, j in 1:n
        if i != j && isfinite(shortest[i,j])
            shortest[i,j] -= tp
        end
    end

    return shortest, lineinfo, directlink, path

end

function check_feasibility(network, lineplan, OD, max_lines, max_stops)
    nbnodes = size(network, 1)
    served_stops = unique(vec(lineplan))
    served_stops = sort(served_stops[served_stops .> 0])
    nonserved_stops = setdiff(1:nbnodes, served_stops)
    
    # Identify problematic stops i.e. stops nonserved yet with a demand
    problematic_stops = Int[]
    for s in nonserved_stops
        if sum(OD[s, :]) + sum(OD[:, s]) > 0
            push!(problematic_stops, s)
        end
    end
    if !isempty(problematic_stops)
        println("Warning: The following stops are not served but they have passenger demand: ", problematic_stops)
    end

    # Check maximum number of lines
    if size(lineplan, 1) > max_lines
        println("Warning: Number of lines exceeds maximum allowed.")
    end

    # Check max stops per line
    for i in eachindex(lineplan[:, 1])
        nstops = count(x -> x != 0, lineplan[i, :])
        if nstops > max_stops
            println("Warning: Line $i exceeds maximum number of stops ($nstops > $max_stops).")
        end
    end

    feasible = isempty(problematic_stops) &&
               size(lineplan, 1) <= max_lines &&
               all(count(x -> x != 0, lineplan[i, :]) <= max_stops for i in eachindex(lineplan[:, 1]))

    return feasible, served_stops, problematic_stops  
end

function reconstruct_shortestroute(origin, destination, path, lineinfo, directlink)
    stops = [origin]
    lines_taken = Int[]
    current = origin

    while current != destination
        next_node = path[current, destination]  # 0 if direct ride
        if next_node == 0
            push!(lines_taken, lineinfo[current, destination])
            push!(stops, destination)
            break
        else
            # transfer occurs at intermediate node
            push!(lines_taken, lineinfo[current, next_node])
            push!(stops, next_node)
            current = next_node
        end
    end

    # compute ridetimes for each segment
    ridetime = [directlink[stops[s], stops[s+1]] for s in 1:length(stops)-1]

    return stops, lines_taken, ridetime
end
