# Emergency Facility Location
#
# Finds the two nodes that minimise the total shortest travel time
# from every usable node to its nearest emergency facility.
#
# Map movement times:
#   Vertical movement   = 15 seconds
#   Horizontal movement = 20 seconds

using Printf

const VERTICAL_TIME = 15.0
const HORIZONTAL_TIME = 20.0


## MAP DEFINITION


const ROWS = 10
const COLS = 5
# set the population of the grid to allow for priority weighting later
population_grid = [
    3 1 4 2 5;
    3 2 3 3 2;
    2 0 3 3 2;
    3 0 0 3 1;
    3 4 3 3 5;
    2 3 4 4 0;
    1 2 0 1 3;
    0 2 0 3 2;
    3 0 0 0 4;
    3 1 0 4 2
]
# The section below is no longer needed as the population grid marks them as zeros already.
# Cells occupied by the abandoned mine
mine_cells = Set([
    (3, 2),
    (4, 2),
    (4, 3)
])

# Cells occupied by the park / pond
park_cells = Set([
    (8, 3),
    (9, 3)
])

# Cells that cannot be used as nodes
blocked_cells = union(mine_cells, park_cells)



## CREATE NODES
function create_nodes()
    nodes = Tuple{Int, Int}[]
    population = Int[]

    for row in 1:ROWS
        for col in 1:COLS

            if !((row, col) in blocked_cells)
                push!(nodes, (row, col))
                push!(populations, population_grid[row, col])
            end

        end
    end

    return nodes, population
end



## CREATE GRAPH

function create_graph(nodes)

    n = length(nodes)

    # Convert grid coordinates to node numbers
    node_index = Dict{Tuple{Int, Int}, Int}()

    for (i, node) in enumerate(nodes)
        node_index[node] = i
    end

    # Adjacency list:
    #
    # graph[i] contains:
    #     (neighbour_node, travel_time)
    #
    graph = [Tuple{Int, Float64}[] for _ in 1:n]

    for (i, (row, col)) in enumerate(nodes)

        # Up
        neighbour = (row - 1, col)

        if haskey(node_index, neighbour)
            j = node_index[neighbour]
            push!(graph[i], (j, VERTICAL_TIME))
        end


        # Down
        neighbour = (row + 1, col)

        if haskey(node_index, neighbour)
            j = node_index[neighbour]
            push!(graph[i], (j, VERTICAL_TIME))
        end


        # Left
        neighbour = (row, col - 1)

        if haskey(node_index, neighbour)
            j = node_index[neighbour]
            push!(graph[i], (j, HORIZONTAL_TIME))
        end


        # Right
        neighbour = (row, col + 1)

        if haskey(node_index, neighbour)
            j = node_index[neighbour]
            push!(graph[i], (j, HORIZONTAL_TIME))
        end

    end

    return graph
end



## DIJKSTRA'S ALGORITHM


function dijkstra(graph, start)

    n = length(graph)

    distance = fill(Inf, n)
    visited = fill(false, n)

    distance[start] = 0.0


    for _ in 1:n

        # Find the unvisited node with the smallest
        # distance discovered so far.

        current = 0
        current_distance = Inf

        for i in 1:n

            if !visited[i] && distance[i] < current_distance
                current = i
                current_distance = distance[i]
            end

        end


        # No more reachable nodes
        if current == 0
            break
        end


        visited[current] = true


        # Check neighbours
        for (next_node, travel_time) in graph[current]

            if visited[next_node]
                continue
            end

            new_distance =
                distance[current] + travel_time


            if new_distance < distance[next_node]

                distance[next_node] =
                    new_distance

            end

        end

    end


    return distance
end



## FIND ALL PAIRS SHORTEST DISTANCES


function all_shortest_distances(graph)

    n = length(graph)

    distances = Matrix{Float64}(undef, n, n)


    for start in 1:n

        distances[start, :] =
            dijkstra(graph, start)

    end


    return distances
end


## FIND BEST TWO FACILITY LOCATIONS
function find_best_facilities(distances)

    n = size(distances, 1)

    best_facility_1 = 0
    best_facility_2 = 0

    best_total_distance = Inf


    # Try every possible pair of facility locations

    for facility1 in 1:n-1

        for facility2 in facility1+1:n

            total_distance = 0.0


            # Every node is serviced by whichever
            # facility is closest.

            for node in 1:n

                distance_to_facility1 =
                    distances[facility1, node]

                distance_to_facility2 =
                    distances[facility2, node]


                closest_distance =
                    min(
                        distance_to_facility1,
                        distance_to_facility2
                    )


                total_distance += closest_distance*population[node]

            end


            # Keep the best pair found so far

            if total_distance < best_total_distance

                best_total_distance =
                    total_distance

                best_facility_1 = facility1
                best_facility_2 = facility2

            end

        end

    end


    return (
        best_facility_1,
        best_facility_2,
        best_total_distance
    )
end



## MAIN PROGRAM


function main()

    nodes, population = create_nodes()

    graph = create_graph(nodes)

    distances = all_shortest_distances(graph)


    facility1,
    facility2,
    total_distance =
        find_best_facilities(distances)


    println("BEST EMERGENCY FACILITY LOCATIONS")
    println("---------------------------------")


    println(
        "Facility 1: Node $facility1 at ",
        nodes[facility1]
    )


    println(
        "Facility 2: Node $facility2 at ",
        nodes[facility2]
    )


    @printf(
        "Total distance to nearest facilities: %.0f seconds\n",
        total_distance
    )


    println()


    # Show which facility serves each node

    println("NODE RESPONSE TIMES")
    println("-------------------")


    for node in 1:length(nodes)

        distance1 =
            distances[facility1, node]

        distance2 =
            distances[facility2, node]


        if distance1 <= distance2

            @printf(
                "Node %-2d %-8s -> Facility 1 : %.0f seconds\n",
                node,
                string(nodes[node]),
                distance1
            )

        else

            @printf(
                "Node %-2d %-8s -> Facility 2 : %.0f seconds\n",
                node,
                string(nodes[node]),
                distance2
            )

        end

    end

end


main()


## KAT IS HERE
# KATS BACK
