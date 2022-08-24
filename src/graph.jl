"""
    graph_from_object(osm_data_object::Union{XMLDocument,Dict};
                      network_type::Symbol=:drive,
                      weight_type::Symbol=:time,
                      graph_type::Symbol=:static,
                      precompute_dijkstra_states::Bool=false,
                      largest_connected_component::Bool=true
                      )::OSMGraph

Creates an `OSMGraph` object from download OpenStreetMap network data, use with 
`download_osm_network`.

# Arguments
- `osm_data_object::Union{XMLDocument,Dict}`: OpenStreetMap network data parsed as either 
    `XMLDocument` or `Dict` object depending on the download method. *NOTE* if you pass in 
    a `Dict`, the object will be modified to add missing tag information.
- `network_type::Symbol=:drive`: Network type filter, pick from `:drive`, `:drive_service`, 
    `:walk`, `:bike`, `:all`, `:all_private`, `:none`, `:rail`, must match the network type 
    used to download `osm_data_object`.
- `weight_type::Symbol=:time`: Weight type for graph edges, pick from `:distance` (km), 
    `:time` (hours), `:lane_efficiency` (time scaled by number of lanes). 
- `graph_type::Symbol=:static`: Type of `Graphs.AbstractGraph`, pick from `:static` 
    (`StaticDiGraph`), `:light` (`DiGraph`), `:simple_weighted` (`SimpleWeightedDiGraph`), 
    `:meta` (`MetaDiGraph`).
- `precompute_dijkstra_states::Bool=false`: Set true to precompute Dijkstra parent states 
    for every source node in the graph, *NOTE* this may take a while and may not be 
    possible for graphs with large amount of nodes due to memory limits.
- `largest_connected_component::Bool=true`: Set true to keep only the largest connected 
    components in the network.

# Return
- `OSMGraph`: Container for storing OpenStreetMap node-, way-, relation- and graph-related 
    obejcts.
"""
function graph_from_object(osm_data_object::Union{XMLDocument,Dict};
                           network_type::Symbol=:drive,
                           weight_type::Symbol=:time,
                           graph_type::Symbol=:static,
                           precompute_dijkstra_states::Bool=false,
                           largest_connected_component::Bool=true
                           )::OSMGraph
    g = init_graph_from_object(osm_data_object, network_type)
    add_node_and_edge_mappings!(g)
    add_weights!(g, weight_type)
    add_graph!(g, graph_type)
    # Finding connected components can only be done after LightGraph object has been constructed
    largest_connected_component && trim_to_largest_connected_component!(g, g.graph, weight_type, graph_type) # Pass in graph to make type stable
    add_node_tags!(g)
    !(network_type in [:bike, :walk]) && add_indexed_restrictions!(g)

    if precompute_dijkstra_states
        add_dijkstra_states!(g)
    else
        U = DEFAULT_OSM_INDEX_TYPE
        g.dijkstra_states = Vector{Vector{U}}(undef, length(g.nodes))
    end

    add_kdtree_and_rtree!(g)
    @info "Created OSMGraph object with kwargs: network_type=$network_type, weight_type=$weight_type, graph_type=$graph_type, precompute_dijkstra_states=$precompute_dijkstra_states, largest_connected_component=$largest_connected_component"
    return g
end

"""
    graph_from_object(file_path::String;
                      network_type::Symbol=:drive,
                      weight_type::Symbol=:time,
                      graph_type::Symbol=:static,
                      precompute_dijkstra_states::Bool=false,
                      largest_connected_component::Bool=true
                      )::OSMGraph

Creates an `OSMGraph` object from a downloaded OpenStreetMap network data file, the extention must be either `.json`, `.osm` or `.xml`.

# Arguments
- `file_path::String`: OpenStreetMap network data file location.
- `network_type::Symbol=:drive`: Network type filter, pick from `:drive`, `:drive_service`, `:walk`, `:bike`, `:all`, `:all_private`, `:none`, `:rail`, must match the network type used to download `osm_data_object`.
- `weight_type::Symbol=:time`: Weight type for graph edges, pick from `:distance` (km), `:time` (hours), `:lane_efficiency` (time scaled by number of lanes). 
- `graph_type::Symbol=:static`: Type of `Graphs.AbstractGraph`, pick from `:static` (StaticDiGraph), `:light` (DiGraph), `:simple_weighted` (SimpleWeightedDiGraph), `:meta` (MetaDiGraph).
- `precompute_dijkstra_states::Bool=false`: Set true to precompute dijkstra parent states for every source node in the graph, *NOTE* this may take a while and may not be possible for graphs with large amount of nodes due to memory limits.
- `largest_connected_component::Bool=true`: Set true to keep only the largest connected components in the network.

# Return
- `OSMGraph`: Container for storing OpenStreetMap node, way, relation and graph related obejcts.
"""
function graph_from_file(file_path::String;
                         network_type::Symbol=:drive,
                         weight_type::Symbol=:time,
                         graph_type::Symbol=:static,
                         precompute_dijkstra_states::Bool=false,
                         largest_connected_component::Bool=true
                         )::OSMGraph

    !isfile(file_path) && throw(ArgumentError("File $file_path does not exist"))
    deserializer = file_deserializer(file_path)
    obj = deserializer(file_path)
    return graph_from_object(obj,
                             network_type=network_type,
                             weight_type=weight_type,
                             graph_type=graph_type,
                             precompute_dijkstra_states=precompute_dijkstra_states,
                             largest_connected_component=largest_connected_component)
end

"""
    graph_from_download(download_method::Symbol;
                        network_type::Symbol=:drive,
                        metadata::Bool=false,
                        download_format::Symbol=:json,
                        save_to_file_location::Union{String,Nothing}=nothing,
                        weight_type::Symbol=:time,
                        graph_type::Symbol=:static,
                        precompute_dijkstra_states::Bool=false,
                        largest_connected_component::Bool=true,
                        download_kwargs...
                        )::OSMGraph

Downloads OpenStreetMap network data and creates an `OSMGraph` object.

# Arguments
- `download_method::Symbol`: Download method, choose from `:place_name`, `:bbox` or `:point`.
- `network_type::Symbol=:drive`: Network type filter, pick from `:drive`, `:drive_service`, `:walk`, `:bike`, `:all`, `:all_private`, `:none`, `:rail`.
- `metadata::Bool=false`: Set true to return metadata.
- `download_format::Symbol=:json`: Download format, either `:osm`, `:xml` or `json`.
- `save_to_file_location::Union{String,Nothing}=nothing`: Specify a file location to save downloaded data to disk.
- `weight_type::Symbol=:time`: Weight type for graph edges, pick from `:distance` (km), `:time` (hours), `:lane_efficiency` (time scaled by number of lanes). 
- `graph_type::Symbol=:static`: Type of `Graphs.AbstractGraph`, pick from `:static` (StaticDiGraph), `:light` (DiGraph), `:simple_weighted` (SimpleWeightedDiGraph), `:meta` (MetaDiGraph).
- `precompute_dijkstra_states::Bool=false`: Set true to precompute dijkstra parent states for every source node in the graph, *NOTE* this may take a while and may not be possible for graphs with large amount of nodes due to memory limits.
- `largest_connected_component::Bool=true`: Set true to keep only the largest connected components in the network.

# Required Kwargs for each Download Method

*`download_method=:place_name`*
- `place_name::String`: Any place name string used as a search argument to the Nominatim API.

*`download_method=:bbox`*
- `minlat::AbstractFloat`: Bottom left bounding box latitude coordinate.
- `minlon::AbstractFloat`: Bottom left bounding box longitude coordinate.
- `maxlat::AbstractFloat`: Top right bounding box latitude coordinate.
- `maxlon::AbstractFloat`: Top right bounding box longitude coordinate.

*`download_method=:point`*
- `point::GeoLocation`: Centroid point to draw the bounding box around.
- `radius::Number`: Distance (km) from centroid point to each bounding box corner.

*`download_method=:polygon`*
- `polygon::AbstractVector`: Vector of longitude-latitude pairs.

# Network Types
- `:drive`: Motorways excluding private and service ways.
- `:drive_service`: Motorways including private and service ways.
- `:walk`: Walkways only.
- `:bike`: Cycleways only.
- `:all`: All motorways, walkways and cycleways excluding private ways.
- `:all_private`: All motorways, walkways and cycleways including private ways.
- `:none`: No network filters.
- `:rail`: Railways excluding proposed and platform.

# Return
- `OSMGraph`: Container for storing OpenStreetMap node, way, relation and graph related obejcts.
"""
function graph_from_download(download_method::Symbol;
                             network_type::Symbol=:drive,
                             metadata::Bool=false,
                             download_format::Symbol=:json,
                             save_to_file_location::Union{String,Nothing}=nothing,
                             weight_type::Symbol=:time,
                             graph_type::Symbol=:static,
                             precompute_dijkstra_states::Bool=false,
                             largest_connected_component::Bool=true,
                             download_kwargs...
                             )::OSMGraph
    obj = download_osm_network(download_method,
                               network_type=network_type,
                               metadata=metadata,
                               download_format=download_format,
                               save_to_file_location=save_to_file_location;
                               download_kwargs...)
    return graph_from_object(obj,
                             network_type=network_type,
                             weight_type=weight_type,
                             graph_type=graph_type,
                             precompute_dijkstra_states=precompute_dijkstra_states,
                             largest_connected_component=largest_connected_component)
end


"""
    add_node_and_edge_mappings!(g::OSMGraph{U,T,W}) where {U <: Integer,T <: Integer,W <: Real}

Adds mappings between nodes, edges and ways to `OSMGraph`.
"""
function add_node_and_edge_mappings!(g::OSMGraph{U,T,W}) where {U <: Integer,T <: Integer,W <: Real}
    for (way_id, way) in g.ways
        @inbounds for (i, node_id) in enumerate(way.nodes)
            if haskey(g.node_to_way, node_id)
                push!(g.node_to_way[node_id], way_id)
            else
                g.node_to_way[node_id] = [way_id]
            end

            if i < length(way.nodes)
                if !way.tags["reverseway"]::Bool
                    o = way.nodes[i] # origin
                    d = way.nodes[i + 1] # destination
                else
                    o = way.nodes[i + 1] # origin and destination reversed
                    d = way.nodes[i]
                end
                
                g.edge_to_way[[o, d]] = way_id

                if !way.tags["oneway"]::Bool
                    g.edge_to_way[[d, o]] = way_id
                end
            end                
        end
    end

    @assert(length(g.nodes) == length(g.node_to_way), "Data quality issue: number of graph nodes ($(length(g.nodes::Dict{T,Node{T}}))) not equal to set of nodes extracted from ways ($(length(g.node_to_way)))")
    g.node_to_index = OrderedDict{T,U}(n => i for (i, n) in enumerate(collect(keys(g.nodes))))
    g.index_to_node = OrderedDict{U,T}(i => n for (n, i) in g.node_to_index)
end

"""
    add_node_tags!(g::OSMGraph)

Adds maxspeed and lanes tags to every `OSMGraph` node.
"""
function add_node_tags!(g::OSMGraph)
    # Custom mean used to minimise allocations
    @inline function _roundedmean(hwys, subkey, T)
        total = zero(T)
        for id in hwys
            total += g.ways[id].tags[subkey]::T
        end
        return round(T, total/length(hwys))
    end
    
    M = DEFAULT_OSM_MAXSPEED_TYPE
    L = DEFAULT_OSM_LANES_TYPE

    for (id, data) in g.nodes
        ways = g.node_to_way[id]
        tags_dict = g.nodes[id].tags::Dict{String, Any}
        tags_dict["maxspeed"] = _roundedmean(ways, "maxspeed", M)
        tags_dict["lanes"] = _roundedmean(ways, "lanes", L)
        push!(g.node_coordinates, [data.location.lat, data.location.lon])
    end
end

"""
    adjacent_node(g::OSMGraph, node::T, way::T)::Union{T,Vector{<:T}} where T <: Integer

Finds the adjacent node id on a given way.
"""
function adjacent_node(g::OSMGraph, node::T, way::T)::Union{T,Vector{<:T}} where T <: Integer
    way_nodes = g.ways[way].nodes
    if node == way_nodes[1]
        return way_nodes[2]
    elseif node == way_nodes[end]
        return way_nodes[length(way_nodes) - 1]
    else
        idx = findfirst(isequal(node), way_nodes)
        is_oneway = g.ways[way].tags["oneway"]
        is_reverseway = g.ways[way].tags["reverseway"]
        if is_oneway && !is_reverseway
            return way_nodes[idx + 1]
        elseif is_oneway && is_reverseway
            return way_nodes[idx - 1]
        else
            # via_node is in the middle of a non-oneway highway, this is only the possible when the 
            # restriction is "only_straight_on", meaning vehicles can neither turn left nor right.
            return [way_nodes[idx - 1], way_nodes[idx + 1]]
        end
    end
end

"""
    add_indexed_restrictions!(g::OSMGraph{U,T,W}) where {U <: Integer,T <: Integer,W <: Real}

Adds restrictions linked lists to `OSMGraph`.

# Example
`[from_way_node_index, ...via_way_node_indices..., to_way_node_index]`
"""
function add_indexed_restrictions!(g::OSMGraph{U,T,W}) where {U <: Integer,T <: Integer,W <: Real}
    g.indexed_restrictions = DefaultDict{U,Vector{MutableLinkedList{U}}}(Vector{MutableLinkedList{U}})

    for (id, r) in g.restrictions
        if r.type == "via_node"
            if r.is_exclusion
                # no_left_turn, no_right_turn, no_u_turn, no_straight_on
                restricted_to_ways = [r.to_way]
            elseif r.is_exclusive
                # only_right_turn, only_left_turn, only_straight_on
                # Multiple to_ways, e.g. if only_right_turn, then left turn and straight on are restricted
                all_ways = g.node_to_way[r.via_node]
                permitted_to_way = r.to_way
                restricted_to_ways = [w for w in all_ways if w != r.from_way && w != permitted_to_way]
            else
                continue
            end

            from_node = adjacent_node(g, r.via_node, r.from_way)::T
            for to_way in restricted_to_ways
                to_node_temp = adjacent_node(g, r.via_node, to_way)
                to_node = isa(to_node_temp, Integer) ? [to_node_temp] : to_node_temp

                for tn in to_node
                    # only_straight_on restrictions may have multiple to_nodes
                    indices = [g.node_to_index[n] for n in [tn, r.via_node::T, from_node]]
                    push!(g.indexed_restrictions[g.node_to_index[r.via_node]], MutableLinkedList{U}(indices...))
                end
            end

        elseif r.type == "via_way"
            via_way_nodes_list = [g.ways[w].nodes for w in r.via_way::Vector{T}]
            via_way_nodes = join_arrays_on_common_trailing_elements(via_way_nodes_list...)::Vector{T}

            from_way_nodes = g.ways[r.from_way].nodes
            from_via_intersection_node = first_common_trailing_element(from_way_nodes, via_way_nodes)
            from_node = adjacent_node(g, from_via_intersection_node, r.from_way)::T

            to_way_nodes = g.ways[r.to_way].nodes
            to_via_intersection_node = first_common_trailing_element(to_way_nodes, via_way_nodes)
            to_node = adjacent_node(g, to_via_intersection_node, r.to_way)::T

            if to_via_intersection_node == via_way_nodes[end]
                # Ordering matters, see doc string, but 
                # we don't want to reorder the array in the Way object
                via_way_nodes = reverse(via_way_nodes)
            end

            indices = [g.node_to_index[n] for n in [to_node, via_way_nodes..., from_node]]
            push!(g.indexed_restrictions[g.node_to_index[to_via_intersection_node]], MutableLinkedList{U}(indices...))
        end
    end
end

"""
    add_weights!(g::OSMGraph, weight_type::Symbol=:distance)

Adds edge weights to `OSMGraph`.
"""
function add_weights!(g::OSMGraph, weight_type::Symbol=:distance)
    n_edges = length(g.edge_to_way)
    o_indices = Vector{Int}(undef, n_edges) # edge origin node indices
    d_indices = Vector{Int}(undef, n_edges) # edge destination node indices
    weights = Vector{Float64}(undef, n_edges)

    W = DEFAULT_OSM_EDGE_WEIGHT_TYPE

    @inbounds for (i, edge) in enumerate(keys(g.edge_to_way))
        o_loc = g.nodes[edge[1]].location
        d_loc = g.nodes[edge[2]].location

        o_indices[i] = g.node_to_index[edge[1]]
        d_indices[i] = g.node_to_index[edge[2]]

        dist = distance(o_loc, d_loc, :haversine)
        if weight_type == :time || weight_type == :lane_efficiency
            highway = g.edge_to_way[edge]
            maxspeed = g.ways[highway].tags["maxspeed"]::DEFAULT_OSM_MAXSPEED_TYPE
            if weight_type == :time
                weight = dist / maxspeed
            else
                lanes = g.ways[highway].tags["lanes"]::DEFAULT_OSM_LANES_TYPE
                lane_efficiency = get(LANE_EFFICIENCY[], lanes, 1.0)
                weight = dist / (maxspeed * lane_efficiency)
            end
        else
            # Distance
            weight = dist
        end
        weights[i] = max(weight, eps(W))
    end

    n = length(g.nodes)
    g.weights = sparse(o_indices, d_indices, weights, n, n)
    g.weight_type = weight_type
    return g
end

"""
    add_graph!(g::OSMGraph, graph_type::Symbol=:static)

Adds a Graphs.AbstractGraph object to `OSMGraph`.
"""
function add_graph!(g::OSMGraph{U, T, W}, graph_type::Symbol=:static) where {U <: Integer, T <: Integer, W <: Real}
    if graph_type == :light
        g.graph = DiGraph{T}(g.weights)
    elseif graph_type == :static
        g.graph = StaticDiGraph{U,U}(StaticDiGraph(DiGraph(g.weights)))
    elseif graph_type == :simple_weighted
        g.graph = SimpleWeightedDiGraph{U,W}(g.weights)
    elseif graph_type == :meta
        g.graph = MetaDiGraph(DiGraph{T}(g.weights))
        for (o, d, w) in zip(findnz(copy(transpose(g.weights)))...)
            set_prop!(g.graph, o, d, :weight, w)
        end
    else
        throw(ErrorException("Graph type $graph_type not implemented"))
    end
end

"""
    trim_to_largest_connected_component!(g::OSMGraph{U, T, W}, graph, weight_type::Symbol=:time, graph_type::Symbol=:static) where {U, T, W}

Trims graph object to the largest connected component.
"""
function trim_to_largest_connected_component!(g::OSMGraph{U, T, W}, graph, weight_type::Symbol=:time, graph_type::Symbol=:static) where {U, T, W}
    cc = weakly_connected_components(graph)
    sort!(cc, by=x -> length(x), rev=true)
    indices_to_delete = flatten(cc[2:end])
    nodes_to_delete = [g.index_to_node[i] for i in indices_to_delete]
    ways_to_delete = Set(flatten([g.node_to_way[n] for n in nodes_to_delete]))
    
    delete_from_dict!(g.nodes, nodes_to_delete, :on_key)
    delete_from_dict!(g.node_to_index, nodes_to_delete, :on_key)
    delete_from_dict!(g.node_to_way, nodes_to_delete, :on_key)
    delete_from_dict!(g.index_to_node, indices_to_delete, :on_key)
    delete_from_dict!(g.ways, ways_to_delete, :on_key)
    delete_from_dict!(g.edge_to_way, ways_to_delete, :on_value)

    for (id, r) in g.restrictions
        if r.via_node !== nothing
            !isempty(intersect([r.via_node::T], nodes_to_delete)) && delete!(g.restrictions, id)
        elseif r.via_way !== nothing
            ways = Set([r.from_way, r.to_way, r.via_way::Vector{T}...])
            !isempty(intersect(ways, ways_to_delete)) && delete!(g.restrictions, id)
        end
    end
    
    # Trim then rebuild graph so indices are in order
    add_node_and_edge_mappings!(g)
    add_weights!(g, weight_type)
    add_graph!(g, graph_type)
    return g
end

"""
    add_dijkstra_states!(g::OSMGraph{U,T,W}) where {U <: Integer,T <: Integer,W <: Real}

Adds precomputed dijkstra states for every source node in `OSMGraph`. Precomputing all dijkstra 
states is a O(V² + ElogV) operation, where E is the number of edges and V is the number of vertices, 
may not be possible for larger graphs. Not recommended for graphs with greater than 50k nodes.

Note: Not using `cost_adjustment`, i.e. not consdering restrictions in dijkstra computation, 
consider adding in the future.
"""
function add_dijkstra_states!(g::OSMGraph{U,T,W}) where {U <: Integer,T <: Integer,W <: Real}
    @warn "Precomputing all dijkstra states is a O(V² + ElogV) operation, may not be possible for larger graphs."
    g.dijkstra_states = Vector{Vector{U}}(undef, n)
    set_dijkstra_state!(g, collect(vertices(g.graph)))
end

"""
    get_cartesian_locations(g::OSMGraph)

Calculates the Cartesian location of all nodes in the graph.

Returns a 3-by-n matrix where each column is the `xyz` coordinates of a node. Column indices 
correspond to the `g.graph` vertex indices.
"""
function get_cartesian_locations(g::OSMGraph)
    node_locations = [index_to_node(g, index).location for index in 1:nv(g.graph)]
    return to_cartesian(node_locations)
end

"""
    add_kdtree_and_rtree!(g::OSMGraph)

Adds k-d tree and R-tree to `OSMGraph` for finding nearest nodes and ways.
"""
function add_kdtree_and_rtree!(g::OSMGraph)
    cartesian_locations = get_cartesian_locations(g)
    add_kdtree!(g, cartesian_locations)
    add_rtree!(g, cartesian_locations)
end

"""
    add_kdtree!(g::OSMGraph)
    add_kdtree!(g::OSMGraph, cartesian_locations::Matrix{Float64})

Adds KDTree to `OSMGraph` for finding nearest neighbours.
"""
function add_kdtree!(g::OSMGraph, cartesian_locations::Matrix{Float64})
    g.kdtree = KDTree(cartesian_locations)
end
function add_kdtree!(g::OSMGraph)
    cartesian_locations = get_cartesian_locations(g)
    add_kdtree!(g, cartesian_locations)
end

""" 
    add_rtree!(g::OSMGraph)
    add_rtree!(g::OSMGraph, cartesian_locations::Matrix{Float64})

Adds an R-tree to `OSMGraph` for finding nearest ways.

# Warning
Make sure to suppress outputs! 
Behaviour as of SpatialIndexing.jl 0.1.3 will print a line for every single OSM way, which 
will flood the terminal if not suppressed. Use with caution for now.
"""
function add_rtree!(g::OSMGraph{U,T,W}, cartesian_locations::Matrix{Float64}) where {U,T,W}
    # Get bounding box for every way ID
    way_ids = collect(keys(g.ways))
    data = map(way_ids) do way_id
        node_indices = node_id_to_index(g, g.ways[way_id].nodes)
        x = [cartesian_locations[1,i] for i in node_indices]
        y = [cartesian_locations[2,i] for i in node_indices]
        z = [cartesian_locations[3,i] for i in node_indices]
        min_pt = (minimum(x), minimum(y), minimum(z))
        max_pt = (maximum(x), maximum(y), maximum(z))
        return SpatialElem(SpatialIndexing.Rect(min_pt, max_pt), way_id, nothing)
    end

    tree = RTree{Float64,3}(T, Nothing)
    SpatialIndexing.load!(tree, data)
    g.rtree = tree
end
function add_rtree!(g::OSMGraph)
    cartesian_locations = get_cartesian_locations(g)
    add_rtree!(g, cartesian_locations)
end

"""
    get_graph_type(g::OSMGraph)

Detects the type of the underlying graph object `g.graph` and returns the Symbol
used to specify that type in `add_graph!`.
"""
function get_graph_type(g::OSMGraph)
    graph_type = typeof(g.graph)

    if graph_type <: DiGraph
        return :light
    elseif graph_type <: StaticDiGraph
        return :static
    elseif graph_type <: SimpleWeightedDiGraph
        return :simple_weighted
    elseif graph_type <: MetaDiGraph
        return :meta
    else
        throw(ErrorException("Graph is of unexpected type $graph_type"))
    end
end