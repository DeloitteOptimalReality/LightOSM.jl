"""
    index_to_node_id(g::OSMGraph, x::DEFAULT_OSM_INDEX_TYPE)
    index_to_node_id(g::OSMGraph, x::Vector{<:DEFAULT_OSM_INDEX_TYPE})

Maps node index to node id.
"""
index_to_node_id(g::OSMGraph{U}, x::U) where U = g.index_to_node[x]
index_to_node_id(g::OSMGraph{U}, x::Vector{<:U}) where U = [index_to_node_id(g, i) for i in x]

"""
    index_to_node(g::OSMGraph, x::DEFAULT_OSM_INDEX_TYPE)
    index_to_node(g::OSMGraph, x::Vector{<:DEFAULT_OSM_INDEX_TYPE})

Maps node index to node object.
"""
index_to_node(g::OSMGraph{U}, x::U) where U = g.nodes[g.index_to_node[x]]
index_to_node(g::OSMGraph{U}, x::Vector{<:U}) where U = [index_to_node(g, i) for i in x]

"""
    node_id_to_index(g::OSMGraph, x::DEFAULT_OSM_ID_TYPE)
    node_id_to_index(g::OSMGraph, x::Vector{<:DEFAULT_OSM_ID_TYPE})

Maps node id to index.
"""
node_id_to_index(g::OSMGraph{U,T}, x::T) where {U,T} = g.node_to_index[x]
node_id_to_index(g::OSMGraph{U,T}, x::Vector{<:T}) where {U,T} = [node_id_to_index(g, i) for i in x]
"""
    node_to_index(g::OSMGraph, x::Node)
    node_to_index(g::OSMGraph, x::Vector{Node})

Maps node object to index.
"""
node_to_index(g::OSMGraph, x::Node) = g.node_to_index[x.id]
node_to_index(g::OSMGraph, x::Vector{Node}) = [node_id_to_index(g, i.id) for i in x]

"""
    index_to_dijkstra_state(g::OSMGraph, x::DEFAULT_OSM_INDEX_TYPE)

Maps node index to dijkstra state (parents).
"""
index_to_dijkstra_state(g::OSMGraph{U}, x::U) where U = g.dijkstra_states[x]
"""
    node_id_to_dijkstra_state(g::OSMGraph, x::DEFAULT_OSM_ID_TYPE)

Maps node id to dijkstra state (parents).
"""
node_id_to_dijkstra_state(g::OSMGraph{U,T}, x::T) where {U,T} = g.dijkstra_states[node_id_to_index(g, x)]
"""
    set_dijkstra_state_with_index!(g::OSMGraph, index::DEFAULT_OSM_INDEX_TYPE, state)

Set dijkstra state (parents) with node index.
"""
set_dijkstra_state_with_index!(g::OSMGraph{U}, index::U, state) where U = push!(g.dijkstra_states, index, state)
"""
    set_dijkstra_state_with_node_id!(g::OSMGraph, index::DEFAULT_OSM_ID_TYPE, state)

Set dijkstra state (parents) with node id.
"""
set_dijkstra_state_with_node_id!(g::OSMGraph{U,T}, node_id::T, state) where {U,T} = push!(g.dijkstra_states, node_id_to_index(g, node_id), state)
"""
    maxspeed_from_index(g, x::DEFAULT_OSM_INDEX_TYPE)
    maxspeed_from_node_id(g, x::DEFAULT_OSM_ID_TYPE)

Get maxspeed from index id or node id.
"""
maxspeed_from_index(g::OSMGraph{U}, x::U) where U = index_to_node(g, x).tags["maxspeed"]
maxspeed_from_node_id(g::OSMGraph{U,T}, x::T) where {U,T} = g.nodes[x].tags["maxspeed"]