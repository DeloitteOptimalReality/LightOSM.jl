"""
    shortest_path(g::OSMGraph,
                  origin,
                  destination;
                  weights=g.weights,
                  restrictions=g.indexed_restrictions,
                  algorithm::Symbol=:dijkstra,
                  save_dijkstra_state::Bool=false,
                  heuristic::Union{Function,Nothing}=nothing
                  )::Vector{U} where {U <: Integer}

Calculates the shortest path between two OpenStreetMap node ids.

# Arguments
- `g::OSMGraph`: Graph container.
- `origin`: Origin OpenStreetMap node or node id.
- `destination`: Destination OpenStreetMap node or node id.
- `weights`: Matrix of node to node edge weights, defaults to `g.weights`.
- `restrictions `: Turn restictions dictionary. Pass in `nothing` to not use
    restrictions, defaults to `g.indexed_restrictions`.
- `algorithm::Symbol=:dijkstra`: Shortest path algorithm, either. `:dijkstra` or `:astar`.
- `save_dijkstra_state::Bool=false`: Option to cache dijkstra parent states from a single source.
- `heuristic::Union{Function,Nothing}=nothing`: Option to use custom astar heuristic, default haversine distance will be used if left blank.

# Return
- `Vector{U}`: Array of OpenStreetMap node ids making up the shortest path.
"""
function shortest_path(g::OSMGraph,
                       origin::U,
                       destination::U;
                       weights=g.weights,
                       restrictions=g.indexed_restrictions,
                       algorithm::Symbol=:dijkstra,
                       save_dijkstra_state::Bool=false,
                       heuristic::Union{Function,Nothing}=nothing
                       )::Vector{U} where {U <: Integer}
    
    o_index = g.node_to_index[origin]
    d_index = g.node_to_index[destination]

    if isassigned(g.dijkstra_states, o_index)
        # State already exists
        parents = g.dijkstra_states[o_index]

    elseif algorithm == :dijkstra
        if save_dijkstra_state
            parents = dijkstra(g.graph, o_index, distmx=weights, restrictions=restrictions)
            g.dijkstra_states[o_index] = parents
        else
            parents = dijkstra(g.graph, o_index; goal=d_index, distmx=weights, restrictions=restrictions)
        end

    elseif algorithm == :astar
        h = heuristic === nothing ? default_heuristic(g) : heuristic
        parents = astar(g.graph, o_index, goal=d_index, distmx=weights, heuristic=h, restrictions=restrictions)

    else
        throw(ErrorException("No such algorthm $algorithm, pick from `:dijkstra` or `:astar`"))
    end
    
    path = path_from_parents(parents, o_index, d_index)
    
    return [g.index_to_node[i] for i in path]
end

function shortest_path(g::OSMGraph,
                       origin::Node{U},
                       destination::Node{U};
                       kwargs...)::Vector{U} where {U <: Integer} 
    return shortest_path(g, origin.id, destination.id; kwargs...)
end

"""
Returns the default heuristic function used in astar shorest path calculation.
"""
function default_heuristic(g::OSMGraph, distance_function::Symbol=:haversine)::Function
    if g.weight_type == :distance
        return (u, v) -> distance(g.node_coordinates[u], g.node_coordinates[v], distance_function)
    elseif g.weight_type == :time || g.weight_type == :lane_efficiency
        return (u, v) -> distance(g.node_coordinates[u], g.node_coordinates[v], distance_function) / g.nodes[g.index_to_node[u]].tags["maxspeed"]
    end
end


"""
    path_from_parents(parents::Vector{U}, origin::V, destination::V)::Vector where {U <: Integer, V <: Integer}

Extracts array of shortest path node ids from a single source dijkstra parent state.

# Arguments
- `parents::Vector{U}`: Array of dijkstra parent states.
- `origin::U`: Origin OpenStreetMap node id.
- `destination::U`: Destination OpenStreetMap node id.

# Return
- `Vector{U}`: Array of OpenStreetMap node ids making up the shortest path.
"""
function path_from_parents(parents::Vector{U}, origin::V, destination::V)::Vector where {U <: Integer,V <: Integer}
    if parents[destination] == 0
        throw(ErrorException("Path does not exist between origin node index $origin and destination node index $destination")) 
    end
    
    src = destination
    path = []
    
    while src != 0 # parent of origin is always 0
        push!(path, src)
        src = parents[src]
    end

    return reverse(path)
end

"""
    weights_from_path(g::OSMGraph{U,T,W}, path::Vector{T}; weights=g.weights)::Vector{W} where {U <: Integer,T <: Integer,W <: Real}

Extracts edge weights from a path using the weight matrix stored in `g.weights` unless
a different matrix is passed to the `weights` kwarg.

# Arguments
- `g::OSMGraph`: Graph container.
- `path::Vector{T}`: Array of OpenStreetMap node ids.
- `weights=g.weights`: the matrix that the edge weights are extracted from. Defaults to `g.weights`.

# Return
- `Vector{W}`: Array of edge weights, distances are in km, time is in hours.
"""
function weights_from_path(g::OSMGraph{U,T,W}, path::Vector{T}; weights=g.weights)::Vector{W} where {U <: Integer,T <: Integer,W <: Real}
    return [weights[g.node_to_index[path[i]], g.node_to_index[path[i + 1]]] for i in 1:length(path) - 1]
end

"""
    total_path_weight(g::OSMGraph{U,T,W}, path::Vector{T}; weights=g.weights)::W where {U <: Integer,T <: Integer,W <: Real}

Extract total edge weight along a path.

# Arguments
- `g::OSMGraph`: Graph container.
- `path::Vector{T}`: Array of OpenStreetMap node ids.
- `weights=g.weights`: the matrix that the edge weights are extracted from. Defaults to `g.weights`.

# Return
- `sum::W`: Total path edge weight, distances are in km, time is in hours.
"""
function total_path_weight(g::OSMGraph{U,T,W}, path::Vector{T}; weights=g.weights)::W where {U <: Integer,T <: Integer,W <: Real}
    sum::W = zero(W)
    for i in 1:length(path) - 1
        sum += weights[g.node_to_index[path[i]], g.node_to_index[path[i + 1]]]
    end
    return sum
end
