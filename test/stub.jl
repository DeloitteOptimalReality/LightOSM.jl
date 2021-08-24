"""
    basic_osm_graph_stub(weight_type=:distance, graph_type=:static)

The graph for the network below is returned, with all ways being two way except for 2004.
The diagram is approximately geospatially correct.

```ascii
                   1001─┐
                     │  └─┐100km/h, way=2002, dual carriageway
    50km/h, way=2001 │    └─┐
                     │      │
                   1002    1006
                     │      │
    50km/h, way=2001 │      │ 100km/h, way=2002, dual carriageway
                     │      │
                   1003    1007─────────1008   (1008 to 1007 is way 2004, 50km/h and one way)
                     │      │
    50km/h, way=2001 │    ┌─┘
                     │  ┌─┘100km/h, way=2002, dual carriageway
                   1004─┘
                     │
    50km/h, way=2003 │
                     │
                   1005
```
"""
function basic_osm_graph_stub(weight_type=:distance, graph_type=:static)
    # Nodes
    lats = [-38.0751637, -38.0752637, -38.0753637, -38.0754637, -38.0755637, -38.0752637, -38.0753637, -38.0753637]
    lons = [145.3326838, 145.3326838, 145.3326838, 145.3326838, 145.3326838, 145.3327838, 145.3327838, 145.3328838]
    node_ids = [1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008]
    nodes = Dict(id => Node(id, GeoLocation(lat, lon), Dict{String, Any}()) for (lat, lon, id) in zip(lats, lons, node_ids))

    # Ways
    way_ids = [2001, 2002, 2003, 2004]
    way_nodes = [
        [1001, 1002, 1003, 1004],
        [1001, 1006, 1007, 1004],
        [1004, 1005],
        [1008, 1007],
    ]
    tag_dicts = [
        Dict{String, Any}("oneway" => false, "reverseway" => false, "maxspeed" => Int16(50),  "lanes" => Int8(2)),
        Dict{String, Any}("oneway" => false, "reverseway" => false, "maxspeed" => Int16(100), "lanes" => Int8(4)),
        Dict{String, Any}("oneway" => false, "reverseway" => false, "maxspeed" => Int16(50),  "lanes" => Int8(2)),
        Dict{String, Any}("oneway" => true,  "reverseway" => false, "maxspeed" => Int16(50),  "lanes" => Int8(1)),
    ]
    ways = Dict(way_id => Way(way_id, nodes, tag_dict) for (way_id, nodes, tag_dict) in zip(way_ids, way_nodes, tag_dicts))

    restriction1 = Restriction(
        3001,
        "via_node",
        Dict{String, Any}("restriction"=>"no_right_turn","type"=>"restriction"),
        2002,
        2001,
        1004,
        nothing,
        true,
        false
    )
    restrictions = Dict(restriction1.id => restriction1)
    U = LightOSM.DEFAULT_OSM_INDEX_TYPE
    T = LightOSM.DEFAULT_OSM_ID_TYPE
    W = LightOSM.DEFAULT_OSM_EDGE_WEIGHT_TYPE
    g = OSMGraph{U,T,W}(nodes=nodes, highways=ways, restrictions=restrictions)
    LightOSM.add_node_and_edge_mappings!(g)
    LightOSM.add_weights!(g, weight_type)
    LightOSM.add_graph!(g, graph_type)
    LightOSM.add_node_tags!(g)
    LightOSM.add_indexed_restrictions!(g)
    g.dijkstra_states = Vector{Vector{U}}(undef, length(g.nodes))
    LightOSM.add_kdtree!(g)
    return g
end