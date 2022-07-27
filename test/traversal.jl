g1, w1 = stub_graph1()
g2, w2 = stub_graph2()
g3, w3 = stub_graph3()

# No goal, returns parents
@test LightOSM.dijkstra(g1, w1, 1) == [0, 1, 1, 1, 4]
@test LightOSM.dijkstra(g2, w2, 1) == [0, 1, 4, 1, 4, 7, 4]
@test LightOSM.dijkstra(g3, w3, 1) == [0, 4, 2, 1, 4]

# With goal, returns shortest path
@test LightOSM.astar(g1, w1, 1, 5) == LightOSM.dijkstra(g1, w1, 1, 5) == [1, 4, 5]
@test LightOSM.astar(g2, w2, 1, 6) == LightOSM.dijkstra(g2, w2, 1, 6) == [1, 4, 7, 6]
@test LightOSM.astar(g3, w3, 1, 3) == LightOSM.dijkstra(g3, w3, 1, 3) == [1, 4, 2, 3]
for (T1, T2) in Base.product((AStar, AStarVector, AStarDict), (Dijkstra, DijkstraVector, DijkstraVector))
    @test LightOSM.astar(T1, g1, w1, 1, 5) == LightOSM.dijkstra(T2, g1, w1, 1, 5) == [1, 4, 5]
    @test LightOSM.astar(T1, g2, w2, 1, 6) == LightOSM.dijkstra(T2, g2, w2, 1, 6) == [1, 4, 7, 6]
    @test LightOSM.astar(T1, g3, w3, 1, 3) == LightOSM.dijkstra(T2, g3, w3, 1, 3) == [1, 4, 2, 3]
end

# Construct shortest path from parents
@test LightOSM.path_from_parents(LightOSM.dijkstra(g1, w1, 1), 5) == [1, 4, 5]
@test LightOSM.path_from_parents(LightOSM.dijkstra(g2, w2, 1), 6) == [1, 4, 7, 6]
@test LightOSM.path_from_parents(LightOSM.dijkstra(g3, w3, 1), 3) == [1, 4, 2, 3]

# astar with heuristic
g = basic_osm_graph_stub()

for T in (AStar, AStarVector, AStarDict)
    LightOSM.astar(
        T,
        g.graph,
        g.weights,
        g.node_to_index[1008],
        g.node_to_index[1003];
        heuristic=LightOSM.distance_heuristic(g)
    ) == [
        g.node_to_index[1008],
        g.node_to_index[1007],
        g.node_to_index[1004],
        g.node_to_index[1003]
    ]

    @test LightOSM.astar(
        T,
        g.graph,
        g.weights,
        g.node_to_index[1008],
        g.node_to_index[1002];
        heuristic=LightOSM.distance_heuristic(g)
    ) == [
        g.node_to_index[1008],
        g.node_to_index[1007],
        g.node_to_index[1004],
        g.node_to_index[1003],
        g.node_to_index[1002]
    ]

    @test LightOSM.astar(
        T,
        g.graph,
        g.weights,
        g.node_to_index[1003],
        g.node_to_index[1008];
        heuristic=LightOSM.distance_heuristic(g)
    ) === nothing
end

# download graph, pick random nodes and test dijkstra and astar equality
data = HTTP.get("https://raw.githubusercontent.com/captchanjack/LightOSMFiles.jl/main/maps/south-yarra.json")
data = JSON.parse(String(data.body))

# distance weights
distance_g = LightOSM.graph_from_object(data; graph_type=:static, weight_type=:distance)
origin = rand(1:length(distance_g.nodes))
destination = rand(1:length(distance_g.nodes))

astar_path = LightOSM.astar(distance_g.graph, distance_g.weights, origin, destination; heuristic=LightOSM.distance_heuristic(distance_g))
dijkstra_path = LightOSM.dijkstra(distance_g.graph, distance_g.weights, origin, destination)
@test astar_path == dijkstra_path

if !isnothing(astar_path) && !isnothing(dijkstra_path)
    @test total_path_weight(distance_g, index_to_node_id(distance_g, astar_path)) == total_path_weight(distance_g, index_to_node_id(distance_g, dijkstra_path))
    @test astar_path[1] == origin
    @test astar_path[end] == destination
end

result = Ref{Bool}(true)
for destination in 1:length(distance_g.nodes)
    # shortest path from vertex 4 to all others
    # vertex 4 is sensitive to heuristic choice (i.e. yields non-optiomal solution if a poor heuristic is chosen)
    local origin = 4
    local astar_path = LightOSM.astar(distance_g.graph, distance_g.weights, origin, destination; heuristic=LightOSM.distance_heuristic(distance_g))
    local dijkstra_path = LightOSM.dijkstra(distance_g.graph, distance_g.weights, origin, destination)
    (isnothing(astar_path) || isnothing(dijkstra_path)) && continue
    result[] = result[] && astar_path == dijkstra_path
    result[] = result[] && total_path_weight(distance_g, index_to_node_id(distance_g, astar_path)) == total_path_weight(distance_g, index_to_node_id(distance_g, dijkstra_path))
    result[] = result[] && astar_path[1] == origin
    result[] = result[] && astar_path[end] == destination
    !result[] && break
end
@test result[]

# time weights
time_g = LightOSM.graph_from_object(data; graph_type=:static, weight_type=:time)
origin = rand(1:length(time_g.nodes))
destination = rand(1:length(time_g.nodes))

astar_path = LightOSM.astar(time_g.graph, time_g.weights, origin, destination; heuristic=LightOSM.time_heuristic(time_g))
dijkstra_path = LightOSM.dijkstra(time_g.graph, time_g.weights, origin, destination)
@test astar_path == dijkstra_path

if !isnothing(astar_path) && !isnothing(dijkstra_path)
    @test total_path_weight(time_g, index_to_node_id(time_g, astar_path)) == total_path_weight(time_g, index_to_node_id(time_g, dijkstra_path))
    @test astar_path[1] == origin
    @test astar_path[end] == destination
end

result[] = true
for destination in 1:length(time_g.nodes)
    # shortest path from vertex 4 to all others
    # vertex 4 is sensitive to heuristic choice (i.e. yields non-optiomal solution if a poor heuristic is chosen)
    local origin = 4
    local astar_path = LightOSM.astar(time_g.graph, time_g.weights, origin, destination; heuristic=LightOSM.time_heuristic(time_g))
    local dijkstra_path = LightOSM.dijkstra(time_g.graph, time_g.weights, origin, destination)
    (isnothing(astar_path) || isnothing(dijkstra_path)) && continue
    result[] = result[] && astar_path == dijkstra_path
    result[] = result[] && total_path_weight(time_g, index_to_node_id(time_g, astar_path)) == total_path_weight(time_g, index_to_node_id(time_g, dijkstra_path))
    result[] = result[] && astar_path[1] == origin
    result[] = result[] && astar_path[end] == destination
    !result[] && break
end
@test result[]