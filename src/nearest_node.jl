"""
    nearest_node(g::OSMGraph, point::GeoLocation)
    nearest_node(g::OSMGraph, points::Vector{GeoLocation})
    nearest_node(g::OSMGraph, point::AbstractVector{<:AbstractFloat})
    nearest_node(g::OSMGraph, points::AbstractVector{<:AbstractVector{<:AbstractFloat}})

Finds the nearest node from a point (specified by a `GeoLocation` or set of Latitude
Longitude coordinates) or `Vector` of points using a `NearestNeighbors.jl` KDTree.

# Arguments
- `g::OSMGraph`: Graph container.
- `point`/`points`: Single point as a `GeoLocation` or `[lat, lon, alt]`, or a `Vector` of such points

# Return
- Tuple of neighbours and straight line euclidean distances from each point `([neighbours...], [dists...])`.
    Tuple elements are `Vector`s if a `Vector` of points is inputted, and numbers if a single point is inputted.
"""
nearest_node(g::OSMGraph, point::AbstractVector{<:AbstractFloat}) = nearest_node(g, GeoLocation(point))
nearest_node(g::OSMGraph, points::AbstractVector{<:AbstractVector{<:AbstractFloat}}) = nearest_node(g, GeoLocation(points))
function nearest_node(g::OSMGraph, point::GeoLocation, skip=(index)->false)
    cartesian_location = reshape([to_cartesian(point)...], (3,1))
    idxs, dists = nn(g.kdtree, cartesian_location, skip)
    return g.index_to_node[idxs[1]], dists[1]
end
function nearest_node(g::OSMGraph, points::AbstractVector{GeoLocation})
    cartesian_locations = to_cartesian(points)
    idxs, dists = nn(g.kdtree, cartesian_locations)
    return [g.index_to_node[index] for index in idxs], dists
end

"""
    nearest_node(g::OSMGraph, node::Node)
    nearest_node(g::OSMGraph, nodes::Vector{<:Node})
    nearest_node(g::OSMGraph, node_ids::AbstractVector{<:Integer})
    nearest_node(g::OSMGraph, node_id::Integer)

Finds the nearest node from a node (specified by the `Node` object or node id) or
`Vector` of nodes using a `NearestNeighbors.jl` KDTree. The origin node itself is
not included in the results.
    
# Arguments
- `g::OSMGraph`: Graph container.
- `node`/`nodes`/`node_id`/`node_ids`: Single node or `Vector` of nodes specified by `Node` objects or id.

# Return
- Tuple of neighbours and straight line euclidean distances from each node `([neighbours...], [dists...])`.
    Tuple elements are `Vector`sif a `Vector` of nodes is inputted, and numbers if a single point is inputted.
"""
nearest_node(g::OSMGraph, node::Node) = nearest_node(g, node.location, (index)->index==g.node_to_index[node.id])
nearest_node(g::OSMGraph, node_id::Integer) = nearest_node(g, g.nodes[node_id])
nearest_node(g::OSMGraph, nodes::Vector{<:Node}) = nearest_node(g, [n.id for n in nodes])
function nearest_node(g::OSMGraph, node_ids::AbstractVector{<:Integer})
    locations = [g.nodes[n].location for n in node_ids]
    cartesian_locations = to_cartesian(locations)
    idxs, dists = knn(g.kdtree, cartesian_locations, 2, true)
    return [g.index_to_node[index[2]] for index in idxs], [d[2] for d in dists]
end


"""
    nearest_nodes(g::OSMGraph, point::GeoLocation, n_neighbours::Integer=1)
    nearest_nodes(g::OSMGraph, points::AbstractVector{GeoLocation}, n_neighbours::Integer=1)
    nearest_nodes(g::OSMGraph, point::AbstractVector{<:AbstractFloat}, n_neighbours::Integer=1)
    nearest_nodes(g::OSMGraph, points::AbstractVector{<:AbstractVector{<:AbstractFloat}}, n_neighbours::Integer=1)

Finds nearest nodes from a point or `Vector` of points using a `NearestNeighbors.jl` KDTree.

# Arguments
- `g::OSMGraph`: Graph container.
- `point`/`points`: Single point as a `GeoLocation` or `[lat, lon, alt]`, or a `Vector` of such points
- `n_neighbours::Integer`: Number of neighbours to query for each point.

# Return
- Tuple of neighbours and straight line euclidean distances from each point `([[neighbours]...], [[dists]...])`.
    Tuple elements are `Vector{Vector}` if a `Vector` of points is inputted, and `Vector` if a single point is inputted.
"""
nearest_nodes(g::OSMGraph, point::Vector{<:AbstractFloat}, n_neighbours::Integer=1) = nearest_nodes(g, GeoLocation(point), n_neighbours)
nearest_nodes(g::OSMGraph, points::Vector{<:Vector{<:AbstractFloat}}, n_neighbours::Integer=1) = nearest_nodes(g, GeoLocation(points), n_neighbours)
function nearest_nodes(g::OSMGraph, point::GeoLocation, n_neighbours::Integer=1, skip=(index)->false)
    cartesian_location = reshape([to_cartesian(point)...], (3,1))
    idxs, dists = knn(g.kdtree, cartesian_location, n_neighbours, true, skip)
    return [g.index_to_node[index] for index in idxs[1]], dists[1]
end
function nearest_nodes(g::OSMGraph, points::AbstractVector{GeoLocation}, n_neighbours::Integer=1)
    cartesian_locations = to_cartesian(points)
    idxs, dists = knn(g.kdtree, cartesian_locations, n_neighbours, true)
    neighbours = [[g.index_to_node[index] for index in _idxs] for _idxs in idxs]
    return neighbours, dists
end

"""
    nearest_nodes(g::OSMGraph, node_id::Integer, n_neighbours::Integer=1)
    nearest_nodes(g::OSMGraph, node_ids::Vector{<:Integer}, n_neighbours::Integer=1)
    nearest_nodes(g::OSMGraph, node::Node, n_neighbours::Integer=1)
    nearest_nodes(g::OSMGraph, nodes::AbstractVector{<:Node}, n_neighbours::Integer=1)

Finds nearest nodes from a point or `Vector` of points using a `NearestNeighbors.jl` KDTree.

# Arguments
- `g::OSMGraph`: Graph container.
- `node`/`nodes`/`node_id`/`node_ids`: Single node or `Vector` of nodes specified by `Node` objects or id.
- `n_neighbours::Integer`: Number of neighbours to query for each point.

# Return
- Tuple of neighbours and straight line euclidean distances from each point `([[neighbours]...], [[dists]...])`.
    Tuple elements are `Vector{Vector}` if a `Vector` of points is inputted, and `Vector` if a single point is inputted.
"""
nearest_nodes(g::OSMGraph, node::Node, n_neighbours::Integer=1) = nearest_nodes(g, node.location, n_neighbours, (index)->index==g.node_to_index[node.id])
nearest_nodes(g::OSMGraph, node_id::Integer, n_neighbours::Integer=1) = nearest_nodes(g, g.nodes[node_id], n_neighbours)
nearest_nodes(g::OSMGraph, nodes::Vector{<:Node}, n_neighbours::Integer=1) = nearest_nodes(g, [n.id for n in nodes], n_neighbours)
function nearest_nodes(g::OSMGraph, node_ids::Vector{<:Integer}, n_neighbours::Integer=1)
    locations = [g.nodes[n].location for n in node_ids]
    n_neighbours += 1 # Closest node is always the input node itself, exclude self from result
    cartesian_locations = to_cartesian(locations)
    idxs, dists = knn(g.kdtree, cartesian_locations, n_neighbours, true)
    return [[g.index_to_node[index] for index in @view(_idxs[2:end])] for _idxs in idxs], [@view(d[2:end]) for d in dists]
end