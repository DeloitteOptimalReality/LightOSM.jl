"""
    shortest_path([PathAlgorithm,]
                  g::OSMGraph,
                  origin::Union{Integer,Node},
                  destination::Union{Integer,Node},
                  [weights::AbstractMatrix=g.weights;
                  cost_adjustment::Function=(u, v, parents) -> 0.0)

Calculates the shortest path between two OpenStreetMap node ids.

# Arguments
- `PathAlgorithm`: Path finding algorithm, choose either `Dijkstra` or `AStar`, defaults to `Dijkstra`.
- `g::OSMGraph`: Graph container.
- `origin::Union{Integer,Node}`: Origin OpenStreetMap node or node id.
- `destination::Union{Integer,Node},`: Destination OpenStreetMap node or node id.
- `weights`: Optional matrix of node to node edge weights, defaults to `g.weights`. If a custom weights matrix
    is being used with algorithm set to `:astar`, make sure that a correct heuristic is being used.
- `cost_adjustment::Function=(u, )`: Option to pass in a function to adjust the cost between each pair
    of vetices `u` and `v`, normally the cost is just the weight between `u` and `v`, `cost_adjustment` takes
    in 3 arguments; `u`, `v` and `parents` to apply an additive cost to the default weight. Defaults no adjustment.
    Use `restriction_cost_adjustment` to consider turn restrictions.
- `heuristic::Function=distance_heuristic(g)`: Use custom heuristic with the `AStar` algorithm only. Defaults to a 
    function h(u, v) -> haversine(u, v), i.e. returns the haversine distances between `u` is the current
    node and `v` is the neighbouring node. If `g.weight_type` is `:time` or `:lane_efficiency` use `time_heuristic(g)`
    instead.

# Return
- `Union{Nothing,Vector{T}}`: Array of OpenStreetMap node ids making up the shortest path.
"""
function shortest_path(::Type{Dijkstra},
                       g::OSMGraph,
                       origin::Integer,
                       destination::Integer,
                       weights::AbstractMatrix;
                       cost_adjustment::Function=(u, v, parents) -> 0.0)
    o_index = node_id_to_index(g, origin)
    d_index = node_id_to_index(g, destination)
    path = dijkstra(g.graph, weights, o_index, d_index; cost_adjustment=cost_adjustment)
    isnothing(path) && return
    return index_to_node_id(g, path)
end
function shortest_path(::Type{AStar},
                       g::OSMGraph,
                       origin::Integer,
                       destination::Integer,
                       weights::AbstractMatrix;
                       cost_adjustment::Function=(u, v, parents) -> 0.0,
                       heuristic::Function=distance_heuristic(g))
    o_index = node_id_to_index(g, origin)
    d_index = node_id_to_index(g, destination)
    path = astar(g.graph, weights, o_index, d_index; cost_adjustment=cost_adjustment, heuristic=heuristic)
    isnothing(path) && return
    return index_to_node_id(g, path)
end
shortest_path(::Type{Dijkstra}, g::OSMGraph, origin::Integer, destination::Integer;  kwargs...) = shortest_path(Dijkstra, g, origin, destination, g.weights; kwargs...)
shortest_path(::Type{Dijkstra}, g::OSMGraph, origin::Node, destination::Node, args...;  kwargs...) = shortest_path(Dijkstra, g, origin.id, destination.id, args...; kwargs...)
shortest_path(::Type{AStar}, g::OSMGraph, origin::Integer, destination::Integer;  kwargs...) = shortest_path(AStar, g, origin, destination, g.weights; kwargs...)
shortest_path(::Type{AStar}, g::OSMGraph, origin::Node, destination::Node, args...;  kwargs...) = shortest_path(AStar, g, origin.id, destination.id, args...; kwargs...)
shortest_path(g::OSMGraph, args...;  kwargs...) = shortest_path(Dijkstra, g, args...; kwargs...)

"""
    set_dijkstra_state!(g::OSMGraph, src::Union{Integer,Vecotr{<:Integer}, weights::AbstractMatrix; cost_adjustment::Function=(u, v, parents) -> 0.0)

Compute and set the dijkstra parent states for one or multiple src vertices. Threads are used for multiple srcs.
Note, computing dijkstra states for all vertices is a O(V² + ElogV) operation, use on large graphs with caution.
"""
function set_dijkstra_state!(g::OSMGraph, src::Integer, weights::AbstractMatrix; cost_adjustment::Function=(u, v, parents) -> 0.0)
    g.dijkstra_states[src] = dijkstra(g.graph, weights, src; cost_adjustment=cost_adjustment)
end
function set_dijkstra_state!(g::OSMGraph, srcs::Vector{<:Integer}, weights::AbstractMatrix; cost_adjustment::Function=(u, v, parents) -> 0.0)
    Threads.@threads for src in srcs
        set_dijkstra_state!(g, src, weights; cost_adjustment=cost_adjustment)
    end
    return g
end
set_dijkstra_state!(g::OSMGraph, src; kwargs...) = set_dijkstra_state!(g, src, g.weights; kwargs...)

"""
    shortest_path_from_dijkstra_state(g::OSMGraph, origin::Integer, destination::Integer)

Extract shortest path from precomputed dijkstra state, from `origin` to `detination` node id.

Note, function will raise `UndefRefError: access to undefined reference` if the dijkstra state of the
origin node is not precomputed.

# Arguments
- `g::OSMGraph`: Graph container.
- `origin::Integer`: Origin OpenStreetMap node or node id.
- `destination::Integer`: Destination OpenStreetMap node or node id.

# Return
- `Union{Nothing,Vector{T}}`: Array of OpenStreetMap node ids making up the shortest path.
"""
function shortest_path_from_dijkstra_state(g::OSMGraph, origin::Integer, destination::Integer)
    parents = node_id_to_dijkstra_state(g, origin)
    path = path_from_parents(parents, node_id_to_index(g, destination))
    isnothing(path) && return
    return index_to_node_id(g, path)
end 

"""
    is_restricted(restriction_ll::MutableLinkedList{V}, u::U, v::U, parents::Vector{U})::Bool where {U <: Integer,V <: Integer}

Given parents, returns `true` if path between `u` and `v` is restricted by the restriction linked list, `false` otherwise.

# Arguments
- `restriction_ll::MutableLinkedList{V}`: Linked list holding vertices in order of v -> parents.
- `u::U`: Current vertex visiting.
- `v::U`: Current neighbour vertex.
- `parents::Vector{U}`: Array of shortest path parents.

# Return
- `Bool`: Returns true if path between `u` and `v` is restricted.
"""
function is_restricted(restriction_ll::MutableLinkedList{V}, u::U, v::U, parents::Vector{U})::Bool where {U <: Integer,V <: Integer}
    current = restriction_ll.node.next

    if v != current.data
        return false
    end

    checked = 1 # already checked v

    while checked < restriction_ll.len
        current = current.next

        if u == current.data
            u = parents[u]
        else
            return false
        end

        checked += 1
    end

    return true
end

"""
    restriction_cost(restrictions::AbstractDict{V,Vector{MutableLinkedList{V}}}, u::U, v::U, parents::Vector{U})::Float64 where {U <: Integer,V <: Integer}

Given parents, returns `Inf64` if path between `u` and `v` is restricted by the set of restriction linked lists, `0.0` otherwise.

# Arguments
- `restrictions::AbstractDict{V,Vector{MutableLinkedList{V}}}`: Set of linked lists holding vertices in order of v -> parents.
- `u::U`: Current vertex visiting.
- `v::U`: Current neighbour vertex.
- `parents::Vector{U}`: Array of shortest path parents.

# Return
- `Float64`: Returns `Inf64` if path between u and v is restricted, `0.0` otherwise.
"""
function restriction_cost(restrictions::AbstractDict{V,Vector{MutableLinkedList{V}}}, u::U, v::U, parents::Vector{U})::Float64 where {U <: Integer,V <: Integer}
    !haskey(restrictions, u) && return 0.0

    for ll in restrictions[u]
        is_restricted(ll, u, v, parents) && return typemax(Float64)
    end

    return 0.0
end

"""
    restriction_cost_adjustment(g::OSMGraph)

Returns the cost adjustment function (user in dijkstra and astar) for restrictions. The return function 
takes 3 arguments, `u` being the current node, `v` being the neighbour node, `parents` being the array 
of parent dijkstra states. By default `g.indexed_restrictions` is used to check whether the path from 
`u` to `v` is restricted given all previous nodes in `parents`.
"""
restriction_cost_adjustment(g::OSMGraph) = (u, v, parents) -> restriction_cost(g.indexed_restrictions, u, v, parents)

"""
    distance_heuristic(g::OSMGraph)

Returns the heuristic function used in astar shortest path calculation, should be used with a graph with
`weight_type=:distance`. The heuristic function takes in 2 arguments, `u` being the current node and `v` 
being the neighbour node, and returns the haversine distance between them.
"""
distance_heuristic(g::OSMGraph) = (u, v) -> haversine(g.node_coordinates[u], g.node_coordinates[v])

"""
    time_heuristic(g::OSMGraph)

Returns the heuristic function used in astar shortest path calculation, should be used with a graph with
`weight_type=:time` or `weight_type=:lane_efficiency`. The heuristic function takes in 2 arguments, `u` 
being the current node and `v` being the neighbour node, and returns the estimated travel time between them. 
Calculated by dividing the harversine distance by a fixed maxspeed of `100`. Remember to achieve an optimal
path, it is important to pick an *underestimating* heuristic that best estimates the cost remaining to the `goal`,
hence we pick the largest maxspeed across all ways.
"""
time_heuristic(g::OSMGraph) = (u, v) -> haversine(g.node_coordinates[u], g.node_coordinates[v]) / 100.0

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
