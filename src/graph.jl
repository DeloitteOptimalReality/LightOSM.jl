"""
    graph_from_object(osm_data_object::Union{XMLDocument,Dict};
                      network_type::Symbol=:drive,
                      weight_type::Symbol=:time,
                      graph_type::Symbol=:static,
                      precompute_dijkstra_states::Bool=false,
                      largest_connected_component::Bool=true
                      )::OSMGraph

Creates an `OSMGraph` object from download OpenStreetMap network data, use with `download_osm_network`.

# Arguments
- `osm_data_object::Symbol`: OpenStreetMap network data parsed as either XML or Dictionary object depending on the download method.
- `network_type::Symbol=:drive`: Network type filter, pick from `:drive`, `:drive_service`, `:walk`, `:bike`, `:all`, `:all_private`, `:none`, `:rail`, must match the network type used to download `osm_data_object`.
- `weight_type::Symbol=:time`: Weight type for graph edges, pick from `:distance` (km), `:time` (hours), `:lane_efficiency` (time scaled by number of lanes). 
- `graph_type::Symbol=:static`: Type of `LightGraphs.AbstractGraph`, pick from `:static` (StaticDiGraph), `:light` (DiGraph), `:simple_weighted` (SimpleWeightedDiGraph), `:meta` (MetaDiGraph).
- `precompute_dijkstra_states::Bool=false`: Set true to precompute dijkstra parent states for every source node in the graph, *NOTE* this may take a while and may not be possible for graphs with large amount of nodes due to memory limits.
- `largest_connected_component::Bool=true`: Set true to keep only the largest connected components in the network.

# Return
- `OSMGraph`: Container for storing OpenStreetMap node, way, relation and graph related obejcts.
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

    add_kdtree!(g)
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
- `graph_type::Symbol=:static`: Type of `LightGraphs.AbstractGraph`, pick from `:static` (StaticDiGraph), `:light` (DiGraph), `:simple_weighted` (SimpleWeightedDiGraph), `:meta` (MetaDiGraph).
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
    !isfile(file_path) && throw(ErrorException("Graph file $file_path does not exist"))
    extension = split(file_path, '.')[end]
    deserializer = file_deserializer(Symbol(extension))
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
                        download_format::Symbol=:osm,
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
- `download_format::Symbol=:osm`: Download format, either `:osm`, `:xml` or `json`.
- `save_to_file_location::Union{String,Nothing}=nothing`: Specify a file location to save downloaded data to disk.
- `weight_type::Symbol=:time`: Weight type for graph edges, pick from `:distance` (km), `:time` (hours), `:lane_efficiency` (time scaled by number of lanes). 
- `graph_type::Symbol=:static`: Type of `LightGraphs.AbstractGraph`, pick from `:static` (StaticDiGraph), `:light` (DiGraph), `:simple_weighted` (SimpleWeightedDiGraph), `:meta` (MetaDiGraph).
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
                             download_format::Symbol=:osm,
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
Adds mappings between nodes, edges and highways to `OSMGraph`.
"""
function add_node_and_edge_mappings!(g::OSMGraph{U,T,W}) where {U <: Integer,T <: Integer,W <: Real}
    for (way_id, way) in g.highways
        @inbounds for (i, node_id) in enumerate(way.nodes)
            if haskey(g.node_to_highway, node_id)
                push!(g.node_to_highway[node_id], way_id)
            else
                g.node_to_highway[node_id] = [way_id]
            end

            if i < length(way.nodes)
                if !way.tags["reverseway"]::Bool
                    o = way.nodes[i] # origin
                    d = way.nodes[i + 1] # destination
                else
                    o = way.nodes[i + 1] # origin and destination reversed
                    d = way.nodes[i]
                end
                
                g.edge_to_highway[[o, d]] = way_id

                if !way.tags["oneway"]::Bool
                    g.edge_to_highway[[d, o]] = way_id
                end
            end                
        end
    end

    @assert(length(g.nodes) == length(g.node_to_highway), "Data quality issue: number of graph nodes ($(length(g.nodes::Dict{T,Node{T}}))) not equal to set of nodes extracted from highways ($(length(g.node_to_highway)))")
    g.node_to_index = OrderedDict{T,U}(n => i for (i, n) in enumerate(collect(keys(g.nodes))))
    g.index_to_node = OrderedDict{U,T}(i => n for (n, i) in g.node_to_index)
end

"""
Adds maxspeed and lanes tags to every `OSMGraph` node.
"""
function add_node_tags!(g::OSMGraph)
    # Custom mean used to minimise allocations
    @inline function _roundedmean(hwys, subkey, T)
        total = zero(T)
        for id in hwys
            total += g.highways[id].tags[subkey]::T
        end
        return round(T, total/length(hwys))
    end
    
    M = DEFAULT_OSM_MAXSPEED_TYPE
    L = DEFAULT_OSM_LANES_TYPE

    for (id, data) in g.nodes
        highways = g.node_to_highway[id]
        tags_dict = g.nodes[id].tags::Dict{String, Any}
        tags_dict["maxspeed"] = _roundedmean(highways, "maxspeed", M)
        tags_dict["lanes"] = _roundedmean(highways, "lanes", L)
        push!(g.node_coordinates, [data.location.lat, data.location.lon])
    end
end

"""
Finds the adjacent node id on a given way.
"""
function adjacent_node(g::OSMGraph, node::T, way::T)::Union{T,Vector{<:T}} where T <: Integer
    way_nodes = g.highways[way].nodes
    if node == way_nodes[1]
        return way_nodes[2]
    elseif node == way_nodes[end]
        return way_nodes[length(way_nodes) - 1]
    else
        idx = findfirst(isequal(node), way_nodes)
        is_oneway = g.highways[way].tags["oneway"]
        is_reverseway = g.highways[way].tags["reverseway"]
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
                all_ways = g.node_to_highway[r.via_node]
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
            via_way_nodes_list = [g.highways[w].nodes for w in r.via_way::Vector{T}]
            via_way_nodes = join_arrays_on_common_trailing_elements(via_way_nodes_list...)::Vector{T}

            from_way_nodes = g.highways[r.from_way].nodes
            from_via_intersection_node = first_common_trailing_element(from_way_nodes, via_way_nodes)
            from_node = adjacent_node(g, from_via_intersection_node, r.from_way)::T

            to_way_nodes = g.highways[r.to_way].nodes
            to_via_intersection_node = first_common_trailing_element(to_way_nodes, via_way_nodes)
            to_node = adjacent_node(g, to_via_intersection_node, r.to_way)::T

            if to_via_intersection_node == via_way_nodes[end]
                # Ordering matters, see doc string
                reverse!(via_way_nodes)
            end

            indices = [g.node_to_index[n] for n in [to_node, via_way_nodes..., from_node]]
            push!(g.indexed_restrictions[g.node_to_index[to_via_intersection_node]], MutableLinkedList{U}(indices...))
        end
    end
end


"""
Adds edge weights to `OSMGraph`.
"""
function add_weights!(g::OSMGraph, weight_type::Symbol=:distance)
    o_locations = Vector{GeoLocation}() # edge origin node locations
    d_locations = Vector{GeoLocation}() # edge destination node locations

    o_indices = Vector{Int}() # edge origin node indices
    d_indices = Vector{Int}() # edge destination node indices

    if weight_type == :time || weight_type == :lane_efficiency
        maxspeeds = Vector{Int}() # km/h
    end

    if weight_type == :lane_efficiency
        lane_efficiency = Vector{Float64}()
    end

    @inbounds for edge in keys(g.edge_to_highway)
        o_loc = g.nodes[edge[1]].location
        d_loc = g.nodes[edge[2]].location
        push!(o_locations, o_loc)
        push!(d_locations, d_loc)

        o_idx = g.node_to_index[edge[1]]
        d_idx = g.node_to_index[edge[2]]
        push!(o_indices, o_idx)
        push!(d_indices, d_idx)

        if weight_type == :time || weight_type == :lane_efficiency
            highway = g.edge_to_highway[edge]
            maxspeed = g.highways[highway].tags["maxspeed"]::DEFAULT_OSM_MAXSPEED_TYPE
            push!(maxspeeds, maxspeed)
        end

        if weight_type == :lane_efficiency
            lanes = g.highways[highway].tags["lanes"]::DEFAULT_OSM_LANES_TYPE
            l_effiency = get(LANE_EFFICIENCY, lanes, 1)
            push!(lane_efficiency, l_effiency)
        end
    end

    W = DEFAULT_OSM_EDGE_WEIGHT_TYPE

    if weight_type == :distance
        weights = max.(distance(o_locations, d_locations, :haversine), eps(W)) # km
    elseif weight_type == :time
        weights = max.(distance(o_locations, d_locations, :haversine) ./ maxspeeds, eps(W))
    elseif weight_type == :lane_efficiency
        weights = max.(distance(o_locations, d_locations, :haversine) ./ (maxspeeds .* lane_efficiency), eps(W))
    end

    n = length(g.nodes)
    g.weights = sparse(o_indices, d_indices, weights, n, n)
    g.weight_type = weight_type
end

"""
Adds a LightGraphs.AbstractGraph object to `OSMGraph`.
"""
function add_graph!(g::OSMGraph, graph_type::Symbol=:static)
    if graph_type == :light
        g.graph = DiGraph(g.weights)
    elseif graph_type == :static
        g.graph = StaticDiGraph(DiGraph(g.weights))
    elseif graph_type == :simple_weighted
        g.graph = SimpleWeightedDiGraph(g.weights)
    elseif graph_type == :meta
        g.graph = MetaDiGraph(DiGraph(g.weights))
        for (o, d, w) in zip(findnz(transpose(g.weights))...)
            set_prop!(g.graph, o, d, :weight, w)
        end
    else
        throw(ErrorException("Graph type $graph_type not implemented"))
    end
end

"""
Trims graph object to the largest connected component.
"""
function trim_to_largest_connected_component!(g::OSMGraph{U, T, W}, graph, weight_type::Symbol=:time, graph_type::Symbol=:static) where {U, T, W}
    cc = weakly_connected_components(graph)
    sort!(cc, by=x -> length(x), rev=true)
    indices_to_delete = flatten(cc[2:end])
    nodes_to_delete = [g.index_to_node[i] for i in indices_to_delete]
    highways_to_delete = Set(flatten([g.node_to_highway[n] for n in nodes_to_delete]))
    
    delete_from_dict!(g.nodes, nodes_to_delete, :on_key)
    delete_from_dict!(g.node_to_index, nodes_to_delete, :on_key)
    delete_from_dict!(g.node_to_highway, nodes_to_delete, :on_key)
    delete_from_dict!(g.index_to_node, indices_to_delete, :on_key)
    delete_from_dict!(g.highways, highways_to_delete, :on_key)
    delete_from_dict!(g.edge_to_highway, highways_to_delete, :on_value)

    for (id, r) in g.restrictions
        if r.via_node !== nothing
            !isempty(intersect([r.via_node::T], nodes_to_delete)) && delete!(g.restrictions, id)
        elseif r.via_way !== nothing
            ways = Set([r.from_way, r.to_way, r.via_way::Vector{T}...])
            !isempty(intersect(ways, highways_to_delete)) && delete!(g.restrictions, id)
        end
    end
    
    # Trim then rebuild graph so indices are in order
    add_node_and_edge_mappings!(g)
    add_weights!(g, weight_type)
    add_graph!(g, graph_type)
    return g
end

"""
Adds precomputed dijkstra states for every source node in `OSMGraph`, not recommended for graphs with greater than 50k nodes.
"""
function add_dijkstra_states!(g::OSMGraph{U,T,W}) where {U <: Integer,T <: Integer,W <: Real}
    srcs = collect(vertices(g.graph)) # source vertices (origin node indices)

    n = length(srcs)
    @info "Precomputing $n Dijkstra States, this might take a while..."
    n > 50000 && @warn "Precomputing and caching all $n Dijkstra States may not be possible due to memory limits"
    g.dijkstra_states = Vector{Vector{U}}(undef, n)

    Threads.@threads for src in srcs
        g.dijkstra_states[src] = dijkstra(g.graph, src, distmx=g.weights, restrictions=g.indexed_restrictions)
    end
end

"""
Adds KDTree to `OSMGraph` for finding nearest neighbours.
"""
function add_kdtree!(g::OSMGraph)
    node_locations = [node.location for (id, node) in g.nodes]  # node locations must have the same order as node indices
    cartesian_locations = to_cartesian(node_locations)
    g.kdtree = KDTree(cartesian_locations)
end
