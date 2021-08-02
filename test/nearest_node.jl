node_ids = keys(g_distance.nodes) # g_distance from graph.jl, using here to avoid successive downloads stopping query
n1_id, state = iterate(node_ids) # doesn't matter what one it is
n2_id, _ = iterate(node_ids, state) # doesn't matter what one it is
n1 = g_distance.nodes[n1_id]
n2 = g_distance.nodes[n2_id]

# Test GeoLocation methods, expect same node to be returned
idxs, dists = nearest_node(g_distance, n1.location)
@test idxs[1][1] == n1.id
@test dists[1][1] == 0.0

# Test vector methods, expect same node to be returned
point1 = [n1.location.lat, n1.location.lon, n1.location.alt]
point2 = [n2.location.lat, n2.location.lon, n2.location.alt]
idxs, dists = nearest_node(g_distance, point1)
@test idxs[1][1] == n1.id
@test dists[1][1] == 0.0
idxs, dists = nearest_node(g_distance, [point1, point2])
@test all(x -> x == n1.id, idxs[1])
@test all(x -> x == n2.id, idxs[2])
@test all(x -> x == 0.0, dists[1])
@test all(x -> x == 0.0, dists[2])

# Test Node methods, expect different node to be returned
idxs, dists = nearest_node(g_distance, n1)
@test idxs[1][1] !== n1.id
@test dists[1][1] !== 0.0
idxs, dists = nearest_node(g_distance, [n1, n2], 2)
@test all(x -> x !== n1.id, idxs[1])
@test all(x -> x !== n2.id, idxs[2])
@test all(x -> x !== 0.0, dists[1])
@test all(x -> x !== 0.0, dists[2])
@test all(length.(idxs) .== 2) # Two points returned
@test all(x -> x[2] > x[1], dists) # 2nd point further away