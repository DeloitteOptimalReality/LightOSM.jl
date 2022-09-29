"""
    nearest_way(g, point, [search_radius])

Finds the nearest way from a point using a `SpatialIndexing.jl` R-tree.

The search area is a cube centred on `point` with an edge length of `2 * search_radius`. If 
`search_radius` is not specified, it is automatically determined from the distance to the 
nearest node. 

A larger `search_radius` will incur a performance penalty as more ways must be checked for 
their closest points. Choose this value carefully according to the desired use case.

# Arguments
- `g::OSMGraph`: Graph container.
- `point`: Single point as a `GeoLocation` or `[lat, lon, alt]`.
- `search_radius::AbstractFloat`: Size of cube to search around `point`.

# Return
- `::Tuple{<:Integer,Float64,EdgePoint}`: If nearest way was found.
    - `::Integer`: Nearest way ID.
    - `::Float64`: Distance to nearest way.
    - `::EdgePoint`: Closest point on the nearest way.
- `::Tuple{Nothing,Nothing,Nothing}`: If no ways were found within `search_radius`.
"""
nearest_way(g::OSMGraph, point::AbstractVector{<:AbstractFloat}, search_radius::Union{Nothing,AbstractFloat}=nothing) = nearest_way(g, GeoLocation(point), search_radius)
function nearest_way(g::OSMGraph{U,T,W}, 
                     point::GeoLocation, 
                     search_radius::Union{Nothing,AbstractFloat}=nothing
                     )::Union{Tuple{T,Float64,EdgePoint},Tuple{Nothing,Nothing,Nothing}} where {U,T,W}
    # Automatically determine search radius from nearest node
    # WARNING: this won't work if there are nodes not attached to a way. This is not
    # currently possible in LightOSM but would need to be changed if this ever happens.
    if isnothing(search_radius)
        _, search_radius = nearest_node(g, point)
    end

    # Get nearest ways
    x = nearest_ways(g, point, search_radius)
    
    # Returning a tuple here to keep it compatible with this syntax:
    # way_ids, dists, ep = nearest_way(g, p, ...)
    isempty(x[1]) && return nothing, nothing, nothing

    # Return the closest way
    _, nearest_idx = findmin(x[2])
    return x[1][nearest_idx], x[2][nearest_idx], x[3][nearest_idx]
end

"""
    nearest_ways(g, point, [search_radius])

Finds nearby ways from a point using a `SpatialIndexing.jl` R-tree.

The search area is a cube centred on `point` with an edge length of `2 * search_radius`. 

A larger `search_radius` will incur a performance penalty as more ways must be checked for 
their closest points. Choose this value carefully according to the desired use case.

# Arguments
- `g::OSMGraph`: Graph container.
- `point`/`points`: Single point as a `GeoLocation` or `[lat, lon, alt]`.
- `search_radius::AbstractFloat=0.1`: Size of cube to search around `point`.

# Return
- `::Tuple{Vector{<:Integer},Vector{Float64},Vector{EdgePoint}}`:
    - `::Vector{<:Integer}`: Nearest way IDs.
    - `::Vector{Float64}`: Distance to each corresponding nearby way.
    - `::Vector{EdgePoint}`: Closest point on each corresponding nearby way.
"""
nearest_ways(g::OSMGraph, point::Vector{<:AbstractFloat}, search_radius::AbstractFloat=0.1) = nearest_ways(g, GeoLocation(point), search_radius)
function nearest_ways(g::OSMGraph{U,T,W}, 
                      point::GeoLocation, 
                      search_radius::AbstractFloat=0.1
                      )::Tuple{Vector{T},Vector{Float64},Vector{EdgePoint}} where {U,T,W}
    # Construct a cube around the point in Cartesian space
    p = to_cartesian(point)
    bbox = SpatialIndexing.Rect(
        (p[1] - search_radius, p[2] - search_radius, p[3] - search_radius),
        (p[1] + search_radius, p[2] + search_radius, p[3] + search_radius)
    )

    # Find all nearby way IDs that intersect with this point
    way_ids = T[T(x.id) for x in intersects_with(g.rtree, bbox)]

    # Calculate distances to each way ID (nearest_points is a vector of tuples)
    nearest_points = nearest_point_on_way.(Ref(g), Ref(point), way_ids)

    return way_ids, [x[2] for x in nearest_points], [x[1] for x in nearest_points]
end

"""
    nearest_point_on_way(g::OSMGraph, point::GeoLocation, way_id::Integer)

Finds the nearest position on a way to a given point. Matches to an `EdgePoint`.

# Arguments
- `g::OSMGraph`: LightOSM graph.
- `point::GeoLocation`: Point to find nearest position to.
- `wid::Integer`: Way ID to search.

# Returns
- `::Tuple`:
  - `::EdgePoint`: Nearest position along the way between two nodes.
  - `::Float64`: Distance from `point` to the nearest position on the way.
"""
function nearest_point_on_way(g::OSMGraph, point::GeoLocation, way_id::Integer)
    nodes = g.ways[way_id].nodes
    min_edge = nothing
    min_dist = floatmax()
    min_pos = 0.0
    for edge in zip(nodes[1:end-1], nodes[2:end])
        x1 = g.nodes[edge[1]].location.lon
        y1 = g.nodes[edge[1]].location.lat
        x2 = g.nodes[edge[2]].location.lon
        y2 = g.nodes[edge[2]].location.lat
        x, y, pos = nearest_point_on_line(x1, y1, x2, y2, point.lon, point.lat)
        d = distance(GeoLocation(y, x), point)
        if d < min_dist
            min_edge = edge
            min_dist = d
            min_pos = pos
        end
    end
    return EdgePoint(min_edge[1], min_edge[2], min_pos), min_dist
end
