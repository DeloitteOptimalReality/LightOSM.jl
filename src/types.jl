"""
Representation of a geospatial coordinates.

- `lat::Float64`: Latitude.
- `lon::Float64`: Longitude.
- `alt::Float64`: Altitude.
"""
@with_kw struct GeoLocation
    lat::Float64
    lon::Float64
    alt::Float64 = 0.0
end

GeoLocation(lat::AbstractFloat, lon::AbstractFloat)::GeoLocation = GeoLocation(lat=lat, lon=lon)
GeoLocation(lat::Real, lon::Real)::GeoLocation = GeoLocation(lat=float(lat), lon=float(lon))
GeoLocation(point::Vector{<:AbstractFloat})::GeoLocation = GeoLocation(point...)
GeoLocation(point::Vector{<:Real})::GeoLocation = GeoLocation([float(coord) for coord in point]...)
GeoLocation(point_vector::Vector{<:Vector{<:Real}})::Vector{GeoLocation} = [GeoLocation(p...) for p in point_vector]

function Base.:(==)(loc1::GeoLocation, loc2::GeoLocation)
    return loc1.lat == loc2.lat && loc1.lon == loc2.lon && loc1.alt == loc2.alt
end
function Base.hash(loc::GeoLocation, h::UInt)
    for field in fieldnames(GeoLocation)
		h = hash(getproperty(loc, field), h)
	end
    return h
end

"""
OpenStreetMap node.

`T<:Integer`
- `id::T`: OpenStreetMap node id.
- `nodes::Vector{T}`: Node's GeoLocation.
- `tags::AbstractDict{String,Any}`: Metadata tags.
"""
struct Node{T <: Integer}
    id::T
    location::GeoLocation
    tags::Union{Dict{String,Any},Nothing}
end

"""
OpenStreetMap way.

`T<:Integer`
- `id::T`: OpenStreetMap way id.
- `nodes::Vector{T}`: Ordered list of node ids making up the way.
- `tags::AbstractDict{String,Any}`: Metadata tags.
"""
struct Way{T <: Integer}
    id::T
    nodes::Vector{T}
    tags::Dict{String,Any}
end
Way(id::T, nodes, tags::Dict{String, Any}) where T <: Integer = Way(id, convert(Vector{T}, nodes), tags)

"""
OpenStreetMap turn restriction (relation).

`T<:Integer`
- `id::T`: OpenStreetMap relation id.
- `type::String`: Either a `via_way` or `via_node` turn restriction.
- `tags::AbstractDict{String,Any}`: Metadata tags.
- `from_way::T`: Incoming way id to the turn restriction.
- `to_way::T`: Outgoing way id to the turn restriction.
- `via_node::Union{T,Nothing}`: Node id at the centre of the turn restriction.
- `via_way::Union{Vector{T},Nothing}`: Way id at the centre of the turn restriction.
- `is_exclusion::Bool`: Turn restrictions such as `no_left_turn`, `no_right_turn` or `no_u_turn`.
- `is_exclusive::Bool`: Turn restrictions such as `striaght_on_only`, `left_turn_only`, `right_turn_only`.
"""
@with_kw struct Restriction{T <: Integer}
    id::T
    type::String
    tags::Dict{String,Any}
    from_way::T
    to_way::T
    via_node::Union{T,Nothing} = nothing
    via_way::Union{Vector{T},Nothing} = nothing
    is_exclusion::Bool = false
    is_exclusive::Bool = false
end 

"""
Container for storing OpenStreetMap node, way, relation and graph related obejcts.

`U <: Integer,T <: Integer,W <: Real`
- `nodes::Dict{T,Node{T}}`: Mapping of node ids to node objects.
- `node_coordinates::Vector{Vector{W}}`: Vector of node coordinates [[lat, lon]...], indexed by graph vertices.
- `ways::Dict{T,Way{T}}`: Mapping of way ids to way objects. Previously called `highways`.
- `node_to_index::OrderedDict{T,U}`: Mapping of node ids to graph vertices.
- `index_to_node::OrderedDict{U,T}`: Mapping of graph vertices to node ids.
- `node_to_way::Dict{T,Vector{T}}`: Mapping of node ids to vector of way ids. Previously called `node_to_highway`.
- `edge_to_way::Dict{Vector{T},T}`: Mapping of edges (adjacent node pairs) to way ids. Previously called `edge_to_highway`.
- `restrictions::Dict{T,Restriction{T}}`: Mapping of relation ids to restriction objects.
- `indexed_restrictions::Union{DefaultDict{U,Vector{MutableLinkedList{U}}},Nothing}`: Mapping of via node ids to ordered sequences of restricted node ids.
- `graph::Union{AbstractGraph,Nothing}`: Either DiGraph, StaticDiGraph, SimpleWeightedDiGraph or MetaDiGraph.
- `weights::Union{SparseMatrixCSC{W,U},Nothing}`: Sparse adjacency matrix (weights between graph vertices), either `:distance` (km), `:time` (hours) or `:lane_efficiency` (time scaled by number of lanes).
- `dijkstra_states::Vector{Vector{U}}`: Vector of dijkstra parent states indexed by source vertices, used to retrieve shortest path from source vertex to any other vertex.
- `kdtree::Union{KDTree,Nothing}`: KDTree used to calculate nearest nodes.
- `weight_type::Union{Symbol,Nothing}`: Either `:distance`, `:time` or `:lane_efficiency`.
"""
@with_kw mutable struct OSMGraph{U <: Integer,T <: Integer,W <: Real}
    nodes::Dict{T,Node{T}} = Dict{T,Node{T}}()
    node_coordinates::Vector{Vector{W}} = Vector{Vector{W}}() # needed for astar heuristic
    ways::Dict{T,Way{T}} = Dict{T,Way{T}}()
    node_to_index::OrderedDict{T,U} = OrderedDict{T,U}()
    index_to_node::OrderedDict{U,T} = OrderedDict{U,T}()
    node_to_way::Dict{T,Vector{T}} = Dict{T,Vector{T}}()
    edge_to_way::Dict{Vector{T},T} = Dict{Vector{T},T}()
    restrictions::Dict{T,Restriction{T}} = Dict{T,Restriction{T}}()
    indexed_restrictions::Union{DefaultDict{U,Vector{MutableLinkedList{U}}},Nothing} = nothing
    graph::Union{AbstractGraph,Nothing} = nothing
    weights::Union{SparseMatrixCSC{W,U},Nothing} = nothing
    dijkstra_states::Union{Vector{Vector{U}},Nothing} = nothing
    kdtree::Union{KDTree{StaticArrays.SVector{3, W}, Euclidean, W}, Nothing} = nothing
    weight_type::Union{Symbol,Nothing} = nothing
end

function Base.getproperty(g::OSMGraph, field::Symbol)
    # Ensure renaming of "highways" to "ways" is backwards compatible
    if field === :highways
        Base.depwarn("`highways` field is deprecated, use `ways` field instead", :getproperty)
        return getfield(g, :ways)
    elseif field === :node_to_highway
        Base.depwarn("`node_to_highway` field is deprecated, use `node_to_way` field instead", :getproperty)
        return getfield(g, :node_to_way)
    elseif field === :edge_to_highway
        Base.depwarn("`edge_to_highway` field is deprecated, use `edge_to_way` field instead", :getproperty)
        return getfield(g, :edge_to_way)
    else
        return getfield(g, field)
    end
end

"""
OpenStreetMap building polygon.

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

"""
PathAlgorithm.

Abstract type for path finding algorithms:
- `Dijkstra`
- `AStar`
"""
abstract type PathAlgorithm end
abstract type Dijkstra <: PathAlgorithm end
abstract type DijkstraVector <: Dijkstra end
abstract type DijkstraDict <: Dijkstra end
abstract type AStar <: PathAlgorithm end
abstract type AStarVector <: AStar end
abstract type AStarDict <: AStar end
