"""
Approximate radius of the Earth (km) used in geoemetry functions.
"""
const RADIUS_OF_EARTH_KM = 6371

"""
Factor used to convert speed from mph to kph units.
"""
const KMH_PER_MPH = 1.60934

"""
URLs to OpenStreetMap APIs.
"""
const OSM_URLS = Dict(
    :nominatim_search => "https://nominatim.openstreetmap.org/search",
    :overpass_map => "http://overpass-api.de/api/interpreter",
    :overpass_status => "https://overpass-api.de/api/status"
)

"""
Exclusion filters used when querying different OpenStreetMap networks.
"""
const WAY_EXCLUSION_FILTERS = Dict(
     :drive_mainroads => Dict(
        "area" => ["yes"],
        "highway" => ["cycleway", "footway", "path", "pedestrian", "steps", "track", "corridor", "elevator", "escalator", "proposed", "construction", "bridleway", "abandoned", "platform", "raceway", "service", "residential"],
        "motor_vehicle" => ["no"],
        "motorcar" => ["no"],
        "access" => ["private"],
        "service" => ["parking", "parking_aisle", "driveway", "private", "emergency_access"]
    ),
    :drive => Dict(
        "area" => ["yes"],
        "highway" => ["cycleway", "footway", "path", "pedestrian", "steps", "track", "corridor", "elevator", "escalator", "proposed", "construction", "bridleway", "abandoned", "platform", "raceway", "service"],
        "motor_vehicle" => ["no"],
        "motorcar" => ["no"],
        "access" => ["private"],
        "service" => ["parking", "parking_aisle", "driveway", "private", "emergency_access"]
    ),
    :drive_service => Dict(
        "area" => ["yes"],
        "highway" => ["cycleway", "footway", "path", "pedestrian", "steps", "track", "corridor", "elevator", "escalator", "proposed", "construction", "bridleway", "abandoned", "platform", "raceway"],
        "motor_vehicle" => ["no"],
        "motorcar" => ["no"],
        "access" => ["private"],
        "service" => ["parking", "parking_aisle", "private", "emergency_access"]
    ),
    :walk => Dict(
        "area" => ["yes"],
        "highway" => ["cycleway", "motor", "proposed", "construction", "abandoned", "platform", "raceway"],
        "foot" => ["no"],
        "access" => ["private"],
        "service" => ["private"]
    ),
    :bike => Dict(
        "area" => ["yes"],
        "highway" => ["footway", "steps", "corridor", "elevator", "escalator", "motor", "proposed", "construction", "abandoned", "platform", "raceway"],
        "bicycle" => ["no"],
        "access" => ["private"],
        "service" => ["private"]
    ),
    :all => Dict(
        "area" => ["yes"],
        "highway" => ["proposed", "construction", "abandoned", "platform", "raceway"],
        "access" => ["private"],
        "service" => ["private"]
    ),
    :all_private => Dict(
        "area" => ["yes"],
        "highway" => ["proposed", "construction", "abandoned", "platform", "raceway"]
    ),
    :none => Dict{AbstractString,Vector{AbstractString}}(),
    :rail => Dict("highway" => ["proposed", "platform"])
)

"""
Concantenates OpenStreetMap exclusion filters into a query string.
"""
function concatenate_exclusions(exclusions::AbstractDict{S,Vector{S}})::S where {S <: AbstractString}
    filters = ""

    for (k, v) in exclusions
        filters *= """["$k"!~"$(join(v, '|'))"]"""
    end

    return filters
end

"""
OpenStreetMap query strings used for different transport networks, to test queries see `https://overpass-api.de/query_form.html`.
"""
const WAY_FILTERS_QUERY = Dict(
    :drive_mainroads => """["highway"]$(concatenate_exclusions(WAY_EXCLUSION_FILTERS[:drive_mainroads]))""",
    :drive => """["highway"]$(concatenate_exclusions(WAY_EXCLUSION_FILTERS[:drive]))""",
    :drive_service => """["highway"]$(concatenate_exclusions(WAY_EXCLUSION_FILTERS[:drive_service]))""",
    :walk => """["highway"]$(concatenate_exclusions(WAY_EXCLUSION_FILTERS[:walk]))""",
    :bike => """["highway"]$(concatenate_exclusions(WAY_EXCLUSION_FILTERS[:bike]))""",
    :all => """["highway"]$(concatenate_exclusions(WAY_EXCLUSION_FILTERS[:all]))""",
    :all_private => """["highway"]$(concatenate_exclusions(WAY_EXCLUSION_FILTERS[:all_private]))""",
    :none => """["highway"]$(concatenate_exclusions(WAY_EXCLUSION_FILTERS[:none]))""",
    :rail => """["railway"]$(concatenate_exclusions(WAY_EXCLUSION_FILTERS[:rail]))"""
)

"""
OpenStreetMap query strings used for getting relation data in addition to nodes and ways that are contained within.
"""
const RELATION_FILTERS_QUERY = Dict(
    :drive_mainroads => """["type"="restriction"]["restriction"][!"conditional"][!"hgv"]""",
    :drive => """["type"="restriction"]["restriction"][!"conditional"][!"hgv"]""",
    :drive_service => """["type"="restriction"]["restriction"][!"conditional"][!"hgv"]""",
    :walk => nothing,
    :bike => nothing,
    :all => """["type"="restriction"]["restriction"][!"conditional"][!"hgv"]""",
    :all_private => """["type"="restriction"]["restriction"][!"conditional"][!"hgv"]""",
    :none => nothing,
    :rail => nothing
)

"""
OpenStreetMap metadata tags.
"""
const OSM_METADATA = Set(["version", "timestamp", "changeset", "uid", "user", "generator", "note", "meta", "count"])

"""
OpenStreetMap download formats.
"""
const OSM_DOWNLOAD_FORMAT = Dict(
    :osm => "xml",
    :xml => "xml",
    :json => "json"
)

"""
Default maxspeed based on highway type. 
"""
const DEFAULT_MAXSPEEDS = Dict(
    "motorway" => 100,
    "trunk" => 100,
    "primary" => 100,
    "secondary" => 100,
    "tertiary" => 50,
    "unclassified" => 50,
    "residential" => 50,
    "other" => 50
)

"""
Default number of lanes based on highway type. 
"""
const DEFAULT_LANES = Dict(
    "motorway" => 3,
    "trunk" => 3,
    "primary" => 2,
    "secondary" => 2,
    "tertiary" => 1,
    "unclassified" => 1,
    "residential" => 1,
    "other" => 1
)

"""
Default oneway attribute based on highway type. 
"""
const DEFAULT_ONEWAY = Dict(
    "motorway" => true,
    "trunk" => true,
    "primary" => false,
    "secondary" => false,
    "tertiary" => false,
    "unclassified" => false,
    "residential" => false,
    "roundabout" => true,
    "other" => false
)

"""
Values that a determine a road is oneway.
"""
const ONEWAY_TRUE = Set(["true", "yes", "1", "-1", 1, -1])

"""
Values that a determine a road is not oneway.
"""
const ONEWAY_FALSE = Set(["false", "no", "0", 0])

"""
Default factor applied to maxspeed when the `lane_efficiency` weight is used to contruct OSMGraph object.
"""
const LANE_EFFICIENCY = Dict(
    1 => 0.7,
    2 => 0.8,
    3 => 0.9,
    4 => 1
)

"""
Default data types used to construct OSMGraph object.
"""
const DEFAULT_DATA_TYPES = Dict(
    :OSM_ID => Int64, # default osm node/highway id date type
    :OSM_INDEX => Int32, # default osm node index data type
    :OSM_EDGE_WEIGHT => Float64, # default osm edge weight data type
    :OSM_MAXSPEED => Int16, # default osm maxspeed data type
    :OSM_LANES => Int8, # default osm lanes data type
)

"""
Default height of buildings in metres.
"""
const DEFAULT_BUILDING_HEIGHT_PER_LEVEL = 4

"""
Default maximum levels of buildings.
"""
const DEFAULT_MAX_BUILDING_LEVELS = 3

"""
Delimiters used to clean maxspeed and lanes data.
"""
const COMMON_OSM_STRING_DELIMITERS = r"[+^:;,|-]"