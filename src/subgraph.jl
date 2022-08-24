"""
    osm_subgraph(g::OSMGraph{U, T, W},
                 vertex_list::Vector{U}
                 )::OSMGraph where {U <: Integer, T <: Integer, W <: Real}

Create an OSMGraph representing a subgraph of another OSMGraph containing 
specified vertices.
The resulting OSMGraph object will also contain vertices from all ways that the
specified vertices (nodes) are members of.
Vertex numbers within the original graph object are not mapped to the subgraph.
"""
function osm_subgraph(g::OSMGraph{U, T, W},
                      vertex_list::Vector{U}
                      ) where {U, T, W}

    # Get all nodes and ways for the subgraph
    nodelist = [g.nodes[g.index_to_node[v]] for v in vertex_list]
    waylist = [g.ways[w] for w in collect(Iterators.flatten([g.node_to_way[n.id] for n in nodelist]))]
    way_ids = [w.id for w in waylist]
    ways = Dict{T, Way{T}}(way_ids .=> waylist)

    # Make sure number of nodes matches number of nodes from ways (adds some nodes to graph)
    for way in values(ways)
        append!(nodelist, g.nodes[n_id] for n_id in g.ways[way.id].nodes)
    end
    unique!(nodelist)
    nodes = Dict{T, Node{T}}([n.id for n in nodelist] .=> nodelist)

    # Get restrictions that involve selected ways
    restrictions = Dict{T, Restriction{T}}()
    for res in values(g.restrictions)
        if in(res.from_way, way_ids) || in(res.to_way, way_ids)
            restrictions[res.id] = res
        end
    end

    # Construct the OSMGraph
    osg = OSMGraph{U, T, W}(nodes=nodes, ways=ways, restrictions=restrictions)
    add_node_and_edge_mappings!(osg)
    !isnothing(g.weight_type) && add_weights!(osg, g.weight_type)
    add_graph!(osg, get_graph_type(g))
    add_node_tags!(osg)

    if isdefined(g.dijkstra_states, 1)
        add_dijkstra_states!(osg)
    else
        osg.dijkstra_states = Vector{Vector{U}}(undef, length(osg.nodes))
    end

    if !isnothing(g.kdtree) || !isnothing(g.rtree)
        cartesian_locations = get_cartesian_locations(g)
        !isnothing(g.kdtree) && add_kdtree!(osg, cartesian_locations)
        !isnothing(g.rtree) && add_rtree!(osg, cartesian_locations)
    end

    return osg
end

function osm_subgraph(g::OSMGraph{U, T, W}, node_list::Vector{T}) where {U <: Integer, T <: Integer, W <: Real} 
    return osm_subgraph(g, [g.node_to_index[n] for n in node_list])
end