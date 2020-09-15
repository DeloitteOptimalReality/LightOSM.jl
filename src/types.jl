"""
Representation of a geospatial coordinates.

# Parameters
- `lat::AbstractFloat`: Latitude.
- `lon::AbstractFloat`: Longitude.
- `alt::AbstractFloat`: Altitude.
"""
@with_kw struct GeoLocation
    lat::AbstractFloat
    lon::AbstractFloat
    alt::AbstractFloat = 0.0
end

GeoLocation(lat::AbstractFloat, lon::AbstractFloat)::GeoLocation = GeoLocation(lat=lat, lon=lon)
GeoLocation(point::Vector{<:AbstractFloat})::GeoLocation = GeoLocation(point...)
GeoLocation(point_vector::Vector{<:Vector{<:AbstractFloat}})::Vector{GeoLocation} = [GeoLocation(p...) for p in point_vector]

"""
OpenStreetMap node.

# Parameters
`T<:Integer`
- `id::T`: OpenStreetMap node id.
- `nodes::Vector{T}`: Node's GeoLocation.
- `tags::AbstractDict{String,Any}`: Metadata tags.
"""
struct Node{T <: Integer}
    id::T
    location::GeoLocation
    tags::Union{AbstractDict{String,Any},Nothing}
end

"""
OpenStreetMap way.

# Parameters
`T<:Integer`
- `id::T`: OpenStreetMap way id.
- `nodes::Vector{T}`: Ordered list of node ids making up the way.
- `tags::AbstractDict{String,Any}`: Metadata tags.
"""
struct Way{T <: Integer}
    id::T
    nodes::Vector{T}
    tags::AbstractDict{String,Any}
end

"""
OpenStreetMap turn restriction (relation).

# Parameters
`T<:Integer`
- `id::T`: OpenStreetMap relation id.
- `type::String`: Either a `via_way` or `via_node` turn restriction.
- `tags::AbstractDict{String,Any}`: Metadata tags.
- `from_way::T`: Incoming way id to the turn restriction.
- `to_way::T`: Outgoing way id to the turn restriction.
- `via_node::Union{T,Nothing} = nothing`: Node id at the centre of the turn restriction.
- `via_way::Union{Vector{T},Nothing} = nothing`: Way id at the centre of the turn restriction.
- `is_exclusion::Bool = false`: Turn restrictions such as `no_left_turn`, `no_right_turn` or `no_u_turn`.
- `is_exclusive::Bool = false`: Turn restrictions such as `striaght_on_only`, `left_turn_only`, `right_turn_only`.
"""
@with_kw struct Restriction{T <: Integer}
    id::T
    type::String
    tags::AbstractDict{String,Any}
    from_way::T
    to_way::T
    via_node::Union{T,Nothing} = nothing
    via_way::Union{Vector{T},Nothing} = nothing
    is_exclusion::Bool = false
    is_exclusive::Bool = false
end 

"""
Container for storing OpenStreetMap node, way, relation and graph related obejcts.

# Parameters
`T<:Integer`
- `id::T`: OpenStreetMap relation id.
- `type::String`: Either a `via_way` or `via_node` turn restriction.
- `tags::AbstractDict{String,Any}`: Metadata tags.
- `from_way::T`: Incoming way id to the turn restriction.
- `to_way::T`: Outgoing way id to the turn restriction.
- `via_node::Union{T,Nothing} = nothing`: Node id at the centre of the turn restriction.
- `via_way::Union{Vector{T},Nothing} = nothing`: Way id at the centre of the turn restriction.
- `is_exclusion::Bool = false`: Turn restrictions such as `no_left_turn`, `no_right_turn` or `no_u_turn`.
- `is_exclusive::Bool = false`: Turn restrictions such as `striaght_on_only`, `left_turn_only`, `right_turn_only`.
"""
@with_kw mutable struct OSMGraph{U <: Integer,T <: Integer,W <: Real}
    nodes::AbstractDict{T,Node{T}} = Dict{T,Node{T}}()
    node_coordinates::Vector{Vector{W}} = Vector{Vector{W}}() # needed for astar heuristic
    highways::AbstractDict{T,Way{T}} = Dict{T,Way{T}}()
    node_to_index::AbstractDict{T,U} = OrderedDict{T,U}()
    index_to_node::AbstractDict{U,T} = OrderedDict{U,T}()
    node_to_highway::AbstractDict{T,Vector{T}} = DefaultDict{T,Vector{T}}(Vector{T})
    edge_to_highway::AbstractDict{Vector{T},T} = Dict{Vector{T},T}()
    restrictions::AbstractDict{T,Restriction{T}} = Dict{T,Restriction{T}}()
    indexed_restrictions::Union{AbstractDict{U,Vector{MutableLinkedList{U}}},Nothing} = nothing
    graph::Union{AbstractGraph,Nothing} = nothing
    weights::Union{SparseMatrixCSC{W,U},Nothing} = nothing
    dijkstra_states::Vector{Vector{U}} = Vector{Vector{U}}()
    kdtree::Union{KDTree,Nothing} = nothing
    weight_type::Union{Symbol,Nothing} = nothing
end

"""
OpenStreetMap building polygon.

# Parameters
`T<:Integer`
- `id::T`: OpenStreetMap building way id.
- `nodes::Vector{T}`: Ordered list of node ids making up the building polyogn.
- `is_outer::Bool`: True if polygon is the outer ring of a multi-polygon.
"""
struct Polygon{T <: Integer}
    id::T
    nodes::Vector{Node{T}}
    is_outer::Bool # or inner
end

"""
OpenStreetMap building.

# Parameters
`T<:Integer`
- `id::T`: OpenStreetMap building way id a simple polygon, relation id if a multi-polygon
- `is_relation::Bool`: True if building is a a multi-polygon / relation.
- `polygons::Vector{Polygon{T}}`: List of building polygons, first is always the outer ring.
- `tags::AbstractDict{String,Any}`: Metadata tags.
"""
struct Building{T <: Integer}
    id::T
    is_relation::Bool # or way
    polygons::Vector{Polygon{T}}
    tags::AbstractDict{String,Any}
end
