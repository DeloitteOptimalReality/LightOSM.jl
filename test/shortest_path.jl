# Basic use
edge = iterate(keys(g_distance.edge_to_highway))[1]
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
path_astar = shortest_path(g_distance, node1_id, node2_id, algorithm=:astar)
@test path_astar==path

# Test edge weight sum equals the weight in g_distance.weights
@test total_path_weight(g_distance, path) == g_distance.weights[g_distance.node_to_index[node1_id],g_distance.node_to_index[node2_id]]
@test total_path_weight(g_distance, path) == sum(weights_from_path(g_distance, path))

# Test time weights
path_time_weights = shortest_path(g_time, node1_id, node2_id)
path_time_weights_astar = shortest_path(g_time, node1_id, node2_id, algorithm=:astar)
@test path_time_weights[1] == node1_id
@test path_time_weights[2] == node2_id
@test path_time_weights == path_time_weights_astar

edge_speed = g_distance.highways[g_distance.edge_to_highway[edge]].tags["maxspeed"]
@test isapprox(total_path_weight(g_distance, path) / total_path_weight(g_time, path), edge_speed)