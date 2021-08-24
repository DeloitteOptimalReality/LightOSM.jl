"""
    to_cartesian(lat::T, lon::T, r::T) where {T} 
    to_cartesian(location::GeoLocation)
    to_cartesian(locations::Vector{GeoLocation})

Converts a vector of GeoLocations to (x, y, z) cartesian coordinates (based on radius of the Earth).
"""
function to_cartesian(lat::T, lon::T, r::T) where {T} 
    x = r * cos(lat) * cos(lon)
    y = r * cos(lat) * sin(lon)
    z = r * sin(lat)
    return x, y, z
end
function to_cartesian(loc::GeoLocation)
    lat = deg2rad(loc.lat)
    lon = deg2rad(loc.lon)
    r = loc.alt + RADIUS_OF_EARTH_KM # approximate radius of earth + alt in km
    x, y, z = to_cartesian(lat, lon, r)
    return x, y, z
end
function to_cartesian(locs::Vector{GeoLocation})
    n_points = length(locs)
    results = Matrix{Float64}(undef, 3, n_points)
    @inbounds for i in 1:n_points
        x, y, z = to_cartesian(locs[i])
        results[1, i] = x
        results[2, i] = y
        results[3, i] = z
    end
    return results
end

"""
    haversine(a_lat::T, a_lon::T, b_lat::T, b_lon::T) where {T}
    haversine(GeoLocation, B::GeoLocation)
    haversine(Node, B::Node)
    haversine(A::Vector{GeoLocation}, B::Vector{GeoLocation})
    haversine(A::Vector{Node}, B::Vector{Node})
    haversine(a::Vector{U}, b::Vector{U})::U where {U <: AbstractFloat}

Calculates the haversine distance (km) between two points.
"""

function haversine(a_lat::T, a_lon::T, b_lat::T, b_lon::T) where {T}
    d = sin((a_lat - b_lat) / 2)^2 + cos(b_lat) * cos(a_lat) * sin((a_lon - b_lon) / 2)^2
    return 2 * RADIUS_OF_EARTH_KM * asin(sqrt(d))
end
function haversine(A::GeoLocation, B::GeoLocation)
    a_lat = deg2rad(A.lat)
    a_lon = deg2rad(A.lon)
    b_lat = deg2rad(B.lat)
    b_lon = deg2rad(B.lon)
    return haversine(a_lat, a_lon, b_lat, b_lon)
end
haversine(a::Node, b::Node) = haversine(a.location, b.location)
haversine(A::Vector{<:GeoLocation}, B::Vector{<:GeoLocation}) = haversine.(A, B)
haversine(A::Vector{<:Node}, B::Vector{<:Node}) = haversine.(A, B)
function haversine(a::Vector{U}, b::Vector{U})::U where {U <: AbstractFloat}
    a_lat = deg2rad(a[1])
    a_lon = deg2rad(a[2])
    b_lat = deg2rad(b[1])
    b_lon = deg2rad(b[2])
    return haversine(a_lat, a_lon, b_lat, b_lon)
end

"""
    euclidean(a_x::T, a_y::T, a_z::T, b_x::T, b_y::T, b_z::T) where {T}
    euclidean(A::GeoLocation, B::GeoLocation)
    euclidean(A::Node, B::Node)
    euclidean(A::Vector{GeoLocation}, B::Vector{GeoLocation})
    euclidean(A::Vector{<:Node}, B::Vector{<:Node})
    euclidean(a::Vector{U}, b::Vector{U})::U where {U <: AbstractFloat}

Calculates the euclidean distance (km) between two points.
"""
euclidean(a_x::T, a_y::T, a_z::T, b_x::T, b_y::T, b_z::T) where {T} = hypot(a_x-b_x, a_y-b_y, a_z-b_z)
euclidean(A::GeoLocation, B::GeoLocation) = euclidean(to_cartesian(A)...,to_cartesian(B)...)
euclidean(a::Node, b::Node) = euclidean(a.location, b.location)
euclidean(A::Vector{GeoLocation}, B::Vector{GeoLocation}) = euclidean.(A, B)
euclidean(A::Vector{<:Node}, B::Vector{<:Node}) = euclidean.(A, B)
function euclidean(a::Vector{U}, b::Vector{U})::U where {U <: AbstractFloat}
    a_lat = deg2rad(a[1])
    a_lon = deg2rad(a[2])
    b_lat = deg2rad(b[1])
    b_lon = deg2rad(b[2])
    return euclidean(
        to_cartesian(a_lat, a_lon, RADIUS_OF_EARTH_KM)...,
        to_cartesian(b_lat, b_lon, RADIUS_OF_EARTH_KM)...
    )
end

"""
    distance(A::Union{Vector{GeoLocation}, GeoLocation, Vector{<:Node}, Node, Vector{<:AbstractFloat}},
             B::Union{Vector{GeoLocation}, GeoLocation, Vector{<:Node}, Node, Vector{<:AbstractFloat}},
             type::Symbol=:haversine
             )

Calculates the distance (km) between two points or two vectors of points.

# Arguments
- `A::Union{Vector{GeoLocation}, GeoLocation, Vector{<:Node}, Node, Vector{<:AbstractFloat}}`: Vector of origin points.
- `B::Union{Vector{GeoLocation}, GeoLocation, Vector{<:Node}, Node, Vector{<:AbstractFloat}}`: Vector of destination points.
- `method::Symbol=:haversine`: Either `:haversine` or `:euclidean`.

# Return
- Distance between origin and destination points in km.
"""
function distance(A::Union{Vector{GeoLocation},GeoLocation,Vector{<:Node},Node,Vector{<:AbstractFloat}},
                  B::Union{Vector{GeoLocation},GeoLocation,Vector{<:Node},Node,Vector{<:AbstractFloat}},
                  method::Symbol=:haversine
                  )
    if method == :haversine
        return haversine(A, B)
    elseif method == :euclidean
        return euclidean(A, B)
    else
        throw(ArgumentError("Distance method $method not implemented"))
    end
end

"""
    heading(a::GeoLocation, b::GeoLocation, return_units::Symbol=:degrees)
    heading(a::Node, b::Node, return_units::Symbol=:degrees)
    heading(A::Vector{GeoLocation}, B::Vector{GeoLocation}, return_units::Symbol=:degrees)
    heading(A::Vector{Node}, B::Vector{Node}, return_units::Symbol=:degrees)

Calculates heading(s) / bearing(s) between two points (`a` is origin, `b` is destination)
or two vectors of points (`A` is vector of origins, `B` is vector of destinations). Points
can be either `GeoLocation`s or `Node`s.

Depending on the `return_units` chosen, the return angle is in range of [-π, π] if `:radians`
or [-180, 180] if `:degrees`. Additionally, adjusts destination longitude in case the straight
line path between a and b crosses the International Date Line.
"""
function heading(a::GeoLocation, b::GeoLocation, return_units::Symbol=:degrees)
    a_lat = a.lat
    a_lon = a.lon
    b_lat = b.lat
    b_lon = b.lon

    # Adjust destination longitude in case straight line path between A and B crosses the International Date Line
    a_lon_left_idx = (b_lon <= a_lon) * ((b_lon + 180) + (180 - a_lon) > (a_lon - b_lon))
    a_lon_right_idx = (b_lon <= a_lon) * ((b_lon + 180) + (180 - a_lon) <= (a_lon - b_lon))

    b_lon_left_idx = (b_lon > a_lon) * ((a_lon + 180) + (180 - b_lon) .< (b_lon - a_lon))
    b_lon_right_idx = (b_lon > a_lon) * ((a_lon + 180) + (180 - b_lon) >= (b_lon - a_lon))

    b_lon_fixed = b_lon_left_idx * (-180 - (180 - b_lon)) +
                  b_lon_right_idx * b_lon +
                  a_lon_left_idx * b_lon +
                  a_lon_right_idx * (180 - abs(-180 - b_lon))

    a_lat = deg2rad(a_lat)
    a_lon = deg2rad(a_lon)
    b_lat = deg2rad(b_lat)
    b_lon_fixed = deg2rad(b_lon_fixed)

    y = sin(b_lon_fixed - a_lon) * cos(b_lat)
    x = cos(a_lat) * sin(b_lat) - sin(a_lat) * cos(b_lat) * cos(b_lon_fixed - a_lon)
    
    heading = atan.(y, x)

    if return_units == :radians
        return heading
    elseif return_units == :degrees
        return rad2deg(heading)
    else
        throw(ArgumentError("Incorrect input for argument `return_units`, choose either `:degrees` or `:radians`"))
    end
end
heading(A::Vector{GeoLocation}, B::Vector{GeoLocation}, return_units::Symbol=:degrees) = heading.(A, B, return_units)
heading(a::Node, b::Node, return_units::Symbol=:degrees)::AbstractFloat = heading(a.location, b.location, return_units)
heading(A::Vector{<:Node}, B::Vector{<:Node}, return_units::Symbol=:degrees) = heading.(A, B, return_units)

"""
    calculate_location(origin::GeoLocation, heading::Number, distance::Number)
    calculate_location(origin::Node, heading::Number, distance::Number)
    calculate_location(origin::Vector{GeoLocation}, heading::Vector{<:Number}, distance::Vector{<:Number})
    calculate_location(origin::Vector{Node}, heading::Vector{<:Number}, distance::Vector{<:Number})

Calculates next location(s) given origin `GeoLocation`(s) or `Node`(s), heading(s) (degrees)
and distance(s) (km).

Locations are returned as `GeoLocation`s.
"""
function calculate_location(origin::GeoLocation, heading::Number, distance::Number)
    lat = deg2rad(origin.lat)
    lon = deg2rad(origin.lon)
    heading = deg2rad(heading)

    lat_final = asin(sin(lat) * cos(distance / RADIUS_OF_EARTH_KM) + cos(lat) * sin(distance / RADIUS_OF_EARTH_KM) * cos(heading))
    lon_final = lon + atan(sin(heading) * sin(distance / RADIUS_OF_EARTH_KM) * cos(lat), cos(distance / RADIUS_OF_EARTH_KM) - sin(lat) * sin(lat_final))

    return GeoLocation(rad2deg(lat_final), rad2deg(lon_final))
end
calculate_location(origins::Vector{GeoLocation}, headings::Vector{<:Number}, distances::Vector{<:Number}) = calculate_location.(origins, headings, distances)
calculate_location(origin::Node, heading::Number, distance::Number)::GeoLocation = calculate_location(origin.location, heading, distance)
calculate_location(origins::Vector{<:Node}, headings::Vector{<:Number}, distances::Vector{<:Number}) = calculate_location.(origins, headings, distances)

"""
    bounding_box_from_point(point::GeoLocation, radius::Number)::NamedTuple

Calculates the coordinates of the bounding box given a centroid point and radius (km).

# Arguments
- `point::GeoLocation`: Centroid of the bounding box as an GeoLocation.
- `radius::Number`: Radius in km of the bounding box (to each corner).

# Return
- `NamedTuple`: Named tuple with attributes minlat, minlon, maxlat, right_lon.
"""
function bounding_box_from_point(point::GeoLocation, radius::Number)::NamedTuple
    bottom_left, top_right = calculate_location([point, point], [225, 45], [radius, radius])
    return (minlat = bottom_left.lat, minlon = bottom_left.lon, maxlat = top_right.lat, maxlon = top_right.lon)
end
