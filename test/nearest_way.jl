Random.seed!(1234)
rand_offset(d=0.000001) = rand() * d * 2 - d

g_int = basic_osm_graph_stub()
g_str = basic_osm_graph_stub_string()
graphs = [g_int, g_str]

for g in graphs
    node_ids = keys(g.nodes)
    # Select a node in the middle of a way
    test_node = rand(node_ids)
    if length(g.node_to_way[test_node]) > 1
        test_node = rand(node_ids)
    end
    test_node_loc = g.nodes[test_node].location
    test_way = g.node_to_way[test_node][1]

    # Point with a tiny offset
    test_point1 = GeoLocation(test_node_loc.lat + rand_offset(), test_node_loc.lon + rand_offset())
    test_dist1 = distance(test_node_loc, test_point1)

    # Point with a massive offset, shouldn't have a nearest way
    test_point2 = GeoLocation(test_node_loc.lat + 1.0, test_node_loc.lon + 1.0)

    # nearest_way
    way_id, dist, ep = nearest_way(g, test_point1)
    @test way_id == test_way
    @test dist <= test_dist1
    @test ep.n1 == test_node || ep.n2 == test_node

    # nearest_way with search_radius
    way_id, dist, ep = nearest_way(g, test_point1, test_dist1)
    @test way_id == test_way
    @test dist <= test_dist1
    @test ep.n1 == test_node || ep.n2 == test_node

    # nearest_ways
    way_ids, dists, eps = nearest_ways(g, test_point1, test_dist1)
    @test test_way in way_ids

    # nearest_way with far away point, automatically choosing search radius
    way_id, dist, ep = nearest_way(g, test_point2)
    @test !isnothing(way_id)

    # nearest_way with far away point, search radius is too small
    way_id, dist, ep = nearest_way(g, test_point2, 0.1)
    @test isnothing(way_id)

    # nearest_ways with far away point, search radius is too small
    way_ids, dists, eps = nearest_ways(g, test_point2, 0.1)
    @test isempty(way_ids)
end
