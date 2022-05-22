"""
    index_to_node_id(g::OSMGraph, x::Integer)
    index_to_node_id(g::OSMGraph, x::Vector{<:Integer})

Maps node index to node id.
"""
index_to_node_id(g::OSMGraph, x::Integer) = g.index_to_node[x]
index_to_node_id(g::OSMGraph, x::Vector{<:Integer}) = [index_to_node_id(g, i) for i in x]

"""
    index_to_node(g::OSMGraph, x::Integer)
    index_to_node(g::OSMGraph, x::Vector{<:Integer})

Maps node index to node object.
"""
index_to_node(g::OSMGraph, x::Integer) = g.nodes[g.index_to_node[x]]
index_to_node(g::OSMGraph, x::Vector{<:Integer}) = [index_to_node(g, i) for i in x]

"""
    node_id_to_index(g::OSMGraph, x::Integer)
    node_id_to_index(g::OSMGraph, x::Vector{<:Integer})

Maps node id to index.
"""
node_id_to_index(g::OSMGraph, x::Integer) = g.node_to_index[x]
node_id_to_index(g::OSMGraph, x::Vector{<:Integer}) = [node_id_to_index(g, i) for i in x]

"""
    node_to_index(g::OSMGraph, x::Node)
    node_to_index(g::OSMGraph, x::Vector{Node})

Maps node object to index.
"""
node_to_index(g::OSMGraph, x::Node) = g.node_to_index[x.id]
node_to_index(g::OSMGraph, x::Vector{Node}) = [node_id_to_index(g, i.id) for i in x]

"""
    index_to_dijkstra_state(g::OSMGraph, x::Integer)

Maps node index to dijkstra state (parents).
"""
index_to_dijkstra_state(g::OSMGraph, x::Integer) = g.dijkstra_states[x]

"""
    node_id_to_dijkstra_state(g::OSMGraph, x::Integer)

Maps node id to dijkstra state (parents).
"""
node_id_to_dijkstra_state(g::OSMGraph, x::Integer) = g.dijkstra_states[node_id_to_index(g, x)]

"""
    set_dijkstra_state_with_index!(g::OSMGraph, index::Integer, state)

Set dijkstra state (parents) with node index.
"""
set_dijkstra_state_with_index!(g::OSMGraph, index::Integer, state) = push!(g.dijkstra_states, index, state)

"""
    set_dijkstra_state_with_node_id!(g::OSMGraph, index::Integer, state)

Set dijkstra state (parents) with node id.
"""
set_dijkstra_state_with_node_id!(g::OSMGraph, node_id::Integer, state) = push!(g.dijkstra_states, node_id_to_index(g, node_id), state)

"""
    maxspeed_from_index(g, x::Integer)
    maxspeed_from_node_id(g, x::Integer)

Get maxspeed from index id or node id.
"""
maxspeed_from_index(g, x::Integer) = index_to_node(g, x).tags["maxspeed"]
maxspeed_from_node_id(g, x::Integer) = g.nodes[x].tags["maxspeed"]