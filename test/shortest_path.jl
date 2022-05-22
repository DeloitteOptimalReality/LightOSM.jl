g_distance = basic_osm_graph_stub()
g_time = basic_osm_graph_stub(:time)

# Basic use
edge = iterate(keys(g_distance.edge_to_way))[1]
node1_id = edge[1]
node2_id = edge[2]
path = shortest_path(g_distance, node1_id, node2_id)
@test path[1] == node1_id
@test path[2] == node2_id

# Test using nodes rather than node IDs get same results
path_from_nodes = shortest_path(g_distance, g_distance.nodes[node1_id], g_distance.nodes[node2_id])
@test path_from_nodes == path

# Pass in weights directly
path_with_weights = shortest_path(g_distance, g_distance.nodes[node1_id], g_distance.nodes[node2_id], g_distance.weights)
@test path_with_weights == path

# Also test astar doesn't error
path_astar = shortest_path(AStar, g_distance, node1_id, node2_id)
@test path_astar==path

# Test edge weight sum equals the weight in g_distance.weights
@test total_path_weight(g_distance, path) == g_distance.weights[g_distance.node_to_index[node1_id], g_distance.node_to_index[node2_id]]
@test total_path_weight(g_distance, path) == sum(weights_from_path(g_distance, path))
n_nodes = length(g_distance.nodes)
ones_weights = ones(n_nodes, n_nodes)
@test total_path_weight(g_distance, path, weights=ones_weights) == 1 * (length(path) - 1)
@test all(weights_from_path(g_distance, path, weights=ones_weights) .== 1)

# Test time weights
path_time_weights = shortest_path(g_time, node1_id, node2_id)
path_time_weights_astar = shortest_path(AStar, g_time, node1_id, node2_id)
@test path_time_weights[1] == node1_id
@test path_time_weights[2] == node2_id
@test path_time_weights == path_time_weights_astar

edge_speed = g_distance.ways[g_distance.edge_to_way[edge]].tags["maxspeed"]
@test isapprox(total_path_weight(g_distance, path) / total_path_weight(g_time, path), edge_speed)

# Test paths we know the result of from the stub graph
path = shortest_path(g_time, 1001, 1004)
@test path == [1001, 1006, 1007, 1004] # this highway is twice the speed so should be quicker
path = shortest_path(g_distance, 1001, 1004)
@test path == [1001, 1002, 1003, 1004]

# Test restriction (and bug fixed in PR #42). Restriction in stub stops 1007 -> 1004 -> 1003 right turn
path = shortest_path(g_distance, 1007, 1003; cost_adjustment=(u, v, parents) -> 0.0)
@test path == [1007, 1004, 1003]
path = shortest_path(g_distance, 1007, 1003; cost_adjustment=restriction_cost_adjustment(g_distance)) # using g.indexed_restrictions in cost_adjustment
@test path == [1007, 1006, 1001, 1002, 1003]

# Test bug fixed in PR #42
g_temp = deepcopy(g_distance)
g_temp.weights[g_temp.node_to_index[1004], g_temp.node_to_index[1003]] = 100
path = shortest_path(g_temp, 1007, 1003; cost_adjustment=(u, v, parents) -> 0.0)
@test path == [1007, 1006, 1001, 1002, 1003]


# Test no path returns nothing
@test isnothing(shortest_path(basic_osm_graph_stub(), 1007, 1008))