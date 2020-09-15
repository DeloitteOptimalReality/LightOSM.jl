function overpass_polygon_buildings_query(geojson_polygons::Vector{Vector{Any}},
                                          metadata::Bool=false,
                                          download_format::Symbol=:osm
                                          )::String
    filters = ""
    for polygon in geojson_polygons
        polygon = map(x -> [x[2], x[1]], polygon) # switch lon-lat to lat-lon
        polygon_str = replace("$polygon", r"[\[,\]]" =>  "")
        filters *= """node["building"](poly:"$polygon_str");<;way["building"](poly:"$polygon_str");>;rel["building"](poly:"$polygon_str");>;"""
    end

    return overpass_query(filters, metadata, download_format)
end

function osm_buildings_from_place_name(;place_name::String,
                                       metadata::Bool=false,
                                       download_format::Symbol=:osm
                                       )::String
    geojson_polygons = polygon_from_place_name(place_name)
    query = overpass_polygon_buildings_query(geojson_polygons, metadata, download_format)
    return overpass_request(query)
end

function osm_buildings_from_bbox(;minlat::Float64,
                                 minlon::Float64,
                                 maxlat::Float64,
                                 maxlon::Float64,
                                 metadata::Bool=false,
                                 download_format::Symbol=:osm
                                 )::String
    filters = """node["building"];<;way["building"];>;rel["building"];>;"""
    bbox = [minlat, minlon, maxlat, maxlon]
    query = overpass_query(filters, metadata, download_format, bbox)
    return overpass_request(query)
end

function osm_buildings_from_point(;point::GeoLocation,
                                  radius::Number,
                                  metadata::Bool=false,
                                  download_format::Symbol=:osm
                                  )::String
    bbox = bounding_box_from_point(point, radius)
    return osm_buildings_from_bbox(;bbox..., metadata=metadata, download_format=download_format)
end

function osm_buildings_downloader(download_method::Symbol)::Function
    if download_method == :place_name
        return osm_buildings_from_place_name
    elseif download_method == :bbox
        return osm_buildings_from_bbox
    elseif download_method == :point
        return osm_buildings_from_point
    else
        throw(ErrorException("OSM buildings downloader $download_method does not exist"))
    end
end

function download_osm_buildings(download_method::Symbol;
                                metadata::Bool=false,
                                download_format::Symbol=:osm,
                                save_to_file_location::Union{String,Nothing}=nothing,
                                download_kwargs...)
    downloader = osm_buildings_downloader(download_method)
    data = downloader(metadata=metadata, download_format=download_format; download_kwargs...)
    @info "Downloaded osm buildings data from $(["$k: $v" for (k, v) in download_kwargs]) in $download_format format"

    if !(save_to_file_location isa Nothing)
        file_extension = "." * String(download_format)

        if !occursin(file_extension, save_to_file_location)
            save_to_file_location *= file_extension
        end

        open(save_to_file_location, "w") do io
            write(io, data)
        end

        @info "Saved osm buildings data to disk: $save_to_file_location"
    end

    deserializer = string_deserializer(download_format)

    return deserializer(data)
end

is_building(tags::Dict)::Bool = haskey(tags, "building") ? true : false

function height(tags::Dict)::Number
    height = get(tags, "height", nothing)
    levels = get(tags, "building:levels", nothing) !== nothing ? tags["building:levels"] : get(tags, "level", nothing)

    if height !== nothing
        return height isa String ? max([remove_non_numeric(h) for h in split(height, r"[+^;,-]")]...) : height
    elseif levels !== nothing
        levels = levels isa String ? round(max([remove_non_numeric(l) for l in split(levels, r"[+^;,-]")]...)) : levels
        levels = levels == 0 ? rand(1:DEFAULT_MAX_BUILDING_LEVELS) : levels
    else
        levels = rand(1:DEFAULT_MAX_BUILDING_LEVELS)
    end

    return levels * DEFAULT_BUILDING_HEIGHT_PER_LEVEL
end

function parse_osm_buildings_dict(osm_buildings_dict::AbstractDict)::Dict{Integer,Building}
    T = DEFAULT_DATA_TYPES[:OSM_ID]
    
    nodes = Dict{T,Node{T}}()
    for node in osm_buildings_dict["node"]
        id = node["id"]
        nodes[id] = Node{T}(
            id,
            GeoLocation(node["lat"], node["lon"]),
            haskey(node, "tags") ? node["tags"] : nothing
        )
    end

    ways = Dict(way["id"] => way for way in osm_buildings_dict["way"]) # for lookup

    added_ways = Set{T}()
    buildings = Dict{T,Building{T}}()
    for relation in osm_buildings_dict["relation"]
        is_relation = true

        if haskey(relation, "tags") && is_building(relation["tags"])
            tags = relation["tags"]
            rel_id = relation["id"]
            members = relation["members"]
            
            polygons = Vector{Polygon{T}}()
            for member in members
                way_id = member["ref"]
                way = ways[way_id]

                haskey(way, "tags") && merge!(tags, way["tags"]) # could potentially overwrite some data
                push!(added_ways, way_id)

                is_outer = member["role"] == "outer" ? true : false
                nds = [nodes[n] for n in way["nodes"]]
                push!(polygons, Polygon(way_id, nds, is_outer))
            end

            tags["height"] = height(tags)
            sort!(polygons, by = x -> x.is_outer, rev=true) # sorting so outer polygon is always first
            buildings[rel_id] = Building{T}(rel_id, is_relation, polygons, tags)
        end
    end

    for (way_id, way) in ways
        is_relation = false
        is_outer = true

        if haskey(way, "tags") && is_building(way["tags"]) && !(way_id in added_ways)
            tags = way["tags"]
            tags["height"] = height(tags)
            nds = [nodes[n] for n in way["nodes"]]
            polygons = [Polygon(way_id, nds, is_outer)]
            buildings[way_id] = Building{T}(way_id, is_relation, polygons, tags)
        end
    end

    return buildings
end

function buildings_from_object(buildings_xml_object::XMLDocument)::Dict{Integer,Building}
    dict_to_parse = osm_dict_from_xml(buildings_xml_object)
    return parse_osm_buildings_dict(dict_to_parse)
end

function buildings_from_file(file_path::String)::Dict{Integer,Building}
    !isfile(file_path) && throw(ErrorException("Buildings file $file_path does not exist"))
    extension = split(file_path, '.')[end]
    deserializer = file_deserializer(Symbol(extension))
    obj = deserializer(file_path)
    return buildings_from_object(obj)
end

function buildings_from_download(download_method::Symbol;
                                 metadata::Bool=false,
                                 download_format::Symbol=:osm,
                                 save_to_file_location::Union{String,Nothing}=nothing,
                                 download_kwargs...
                                 )::Dict{Integer,Building}
    obj = download_osm_buildings(download_method,
                                 metadata=metadata,
                                 download_format=download_format,
                                 save_to_file_location=save_to_file_location;
                                 download_kwargs...)
    return buildings_from_object(obj)
end
