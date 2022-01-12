"""
    nearest_node(g::OSMGraph,
                 points::Vector{GeoLocation},
                 n_neighbours::Integer=1
                 )::Tuple{Vector{Vector{Integer}}, Vector{Vector{AbstractFloat}}}

Finds nearest nodes from a vector of GeoLocations using a `NearestNeighbors.jl` KDTree.

# Arguments
- `g::OSMGraph`: Graph container.
- `points::Vector{GeoLocation}`: Vector of query points.
- `n_neighbours::Integer`: Number of neighbours to query for each point.

# Return
- Tuple of neighbours and straight line euclidean distances from each point `([[neighbours]...], [[dists]...])`.
"""
function nearest_node(g::OSMGraph{U, T, W},
                      points::Vector{GeoLocation},
                      n_neighbours::Integer=1
                      )::Tuple{Vector{Vector{T}},Vector{Vector{Float64}}} where {U, T, W}
    cartesian_locations = LightOSM.to_cartesian(points)
    idxs, dists = knn(g.kdtree, cartesian_locations, n_neighbours, true)
    neighbours = [[g.index_to_node[j] for j in i] for i in idxs]
    dists = collect(dists)
    return  neighbours, dists
end

nearest_node(g::OSMGraph, point::GeoLocation, n_neighbours::Integer=1) = nearest_node(g, [point], n_neighbours)
nearest_node(g::OSMGraph, points::Vector{<:Vector{<:AbstractFloat}}, n_neighbours::Integer=1) = nearest_node(g, GeoLocation(points), n_neighbours)
nearest_node(g::OSMGraph, point::Vector{<:AbstractFloat}, n_neighbours::Integer=1) = nearest_node(g, GeoLocation(point), n_neighbours)

"""
Finds nearest nodes from a vector of node ids, the query node id is excluded from neighbours.
"""
function nearest_node(g::OSMGraph{U, T, W},
                      nodes::Vector{<:Integer},
                      n_neighbours::Integer=1
                      )::Tuple{Vector{Vector{T}},Vector{Vector{Float64}}} where {U, T, W}
    locations = [g.nodes[n].location for n in nodes]
    n_neighbours += 1 # Closest node is always the input node itself, exclude self from result
    neighbours, dists = nearest_node(g, locations, n_neighbours)
    return [n[2:end] for n in neighbours], [d[2:end] for d in dists]
end

nearest_node(g::OSMGraph, node::Integer, n_neighbours::Integer=1) = nearest_node(g, [node], n_neighbours)
nearest_node(g::OSMGraph, nodes::Vector{<:Node}, n_neighbours::Integer=1) = nearest_node(g, [n.id for n in nodes], n_neighbours)
nearest_node(g::OSMGraph, node::Node, n_neighbours::Integer=1) = nearest_node(g, node.id, n_neighbours)
