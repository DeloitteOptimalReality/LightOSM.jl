# Using LightOSM in Unit Tests

To avoid having to download graphs within unit tests, it is suggested that something
similar to the `OSMGraph` stub used in LightOSM's own tests (see [`test/stub.jl`](https://github.com/DeloitteOptimalReality/LightOSM.jl/blob/master/test/stub.jl)) is
used by your package. This allows you to have explicit control over the structure of
the graph and therefore to have explicit tests.

### Manual Stub Creation

To create your own graph stub, the nodes and ways must be manually created and inputted.
Restrictions can also be optionally added.

#### Nodes

Nodes must be have an ID and GeoLocation

```julia
lats = [-38.0751637, -38.0752637, -38.0753637, -38.0754637]
lons = [145.3326838, 145.3326838, 145.3326838, 145.3326833]
node_ids = [1001, 1002, 1003, 1004]
nodes = Dict(
    id => Node(
        id,
        GeoLocation(lat, lon),
        Dict{String, Any}() # Don't need tags
    ) for (lat, lon, id) in zip(lats, lons, node_ids)
)
```

#### Ways

Ways must have an ID, a node list that only includes nodes you have defined and
must include the tags in the example shown below.

```julia
way_ids = [2001, 2002]
way_nodes = [
    [1001, 1002, 1003],
    [1003, 1004],
]
tag_dicts = [
    Dict{String, Any}(
        "oneway" => false,
        "reverseway" => false,
        "maxspeed" => Int16(50),
        "lanes" => Int8(2)
    ),
    Dict{String, Any}(
        "oneway" => false,
        "reverseway" => false,
        "maxspeed" => Int16(50),
        "lanes" => Int8(2)
    ),
]
ways = Dict(way_id => Way(way_id, nodes, tag_dict) for (way_id, nodes, tag_dict) in zip(way_ids, way_nodes, tag_dicts))
```

#### Graph creation

!!! warning
    The functions here are not part of the stable API and will be replaced by a `generate_graph` function or similar

Creating the graph relies on some LightOSM internals to populate all other fields of the `OSMGraph` object

```julia
U = LightOSM.DEFAULT_OSM_INDEX_TYPE
T = LightOSM.DEFAULT_OSM_ID_TYPE
W = LightOSM.DEFAULT_OSM_EDGE_WEIGHT_TYPE
g = OSMGraph{U,T,W}(nodes=nodes, ways=ways)
LightOSM.add_node_and_edge_mappings!(g)
LightOSM.add_weights!(g, :distance) # or :time
LightOSM.add_graph!(g, :static) # or any desired graph type
LightOSM.add_node_tags!(g)
g.dijkstra_states = Vector{Vector{U}}(undef, length(g.nodes))
LightOSM.add_kdtree!(g)
```

#### Restrictions

Optionally, restrictions can be added.

```julia
restriction1 = Restriction(
    3001,
    "via_node",
    Dict{String, Any}("restriction"=>"only_straight_on","type"=>"restriction"),
    2001,
    2002,
    1003, # must be set if restriction is via_node
    nothing, # must be set if restriction is via_way
    false, # true for no_left_turn, no_right_turn, no_u_turn, no_straight_on
    true # true for only_right_turn, only_left_turn, only_straight_on
)
restrictions = Dict(restriction1.id => restriction1)
```

See [`Restriction`](@ref) for more information on `Restriction` objects.

And then when instantiating the `OSMGraph`

```julia
g = OSMGraph{U,T,W}(nodes=nodes, ways=ways, restrictions=restrictions)
LightOSM.add_indexed_restrictions!(g)
```

### Using the LightOSM stub

!!! danger "This is not part of the API"
    Using this function is not part of the packages API, and thereore may change without respecting Semantic Versioning. It is suggested to create your own stub for your own package, rather than using this.

To use the stub provided in LightOSM, run the following in your tests

```julia
using LightOSM
include(joinpath(pathof(LightOSM), "test", "stub.jl"))
g = basic_osm_graph_stub()
```