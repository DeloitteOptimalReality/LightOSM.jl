"""
    to_matrix(locations::Vector{GeoLocation})::Matrix{AbstractFloat}

Converts a vector of GeoLocations to a matrix where the columns are in order of: latitude, longitude, altitude.
"""
function to_matrix(locations::Vector{GeoLocation})::Matrix{AbstractFloat}
    return hcat([[loc.lat, loc.lon, loc.alt] for loc in locations]...)'
end

"""
    to_cartesian(location::Vector{GeoLocation})::Matrix{<:AbstractFloat}

Converts a vector of GeoLocations to (x, y, z) cartesian coordinates (based on radius of the Earth).
"""
function to_cartesian(location::Vector{GeoLocation})::Matrix{<:AbstractFloat}
    L = to_matrix(location)

    lats = deg2rad.(L[:,1])
    lons = deg2rad.(L[:,2])
    alts = L[:,3]

    r = alts .+ RADIUS_OF_EARTH_KM # approximate radius of earth + alt in km
    x = r .* cos.(lats) .* cos.(lons)
    y = r .* cos.(lats) .* sin.(lons)
    z = r .* sin.(lats)
    return hcat(x, y, z)
end

to_cartesian(location::GeoLocation)::Vector{AbstractFloat} = to_cartesian([location])[1,:]

"""
    haversine(A::Vector{GeoLocation}, B::Vector{GeoLocation})::Vector{AbstractFloat}

Calculates the haversine distance (km) between two points.
"""
function haversine(A::Vector{GeoLocation}, B::Vector{GeoLocation})::Vector{AbstractFloat}
    A = to_matrix(A)
    B = to_matrix(B)

    a_lat = deg2rad.(A[:,1])
    a_lon = deg2rad.(A[:,2])
    b_lat = deg2rad.(B[:,1])
    b_lon = deg2rad.(B[:,2])
    
    d = sin.((a_lat - b_lat) / 2).^2 + cos.(b_lat) .* cos.(a_lat) .* sin.((a_lon - b_lon) / 2).^2
    return 2 * RADIUS_OF_EARTH_KM * asin.(sqrt.(d))
end

haversine(a::GeoLocation, b::GeoLocation)::AbstractFloat = haversine([a], [b])[1]
haversine(A::Vector{<:Node}, B::Vector{<:Node})::Vector{AbstractFloat} = haversine([n.location for n in A], [n.location for n in B])
haversine(a::Node, b::Node)::AbstractFloat = haversine([a], [b])[1]

function haversine(a::Vector{U}, b::Vector{U})::U where {U <: AbstractFloat}
    a_lat = deg2rad(a[1])
    a_lon = deg2rad(a[2])
    b_lat = deg2rad(b[1])
    b_lon = deg2rad(b[2])

    d = sin((a_lat - b_lat) / 2)^2 + cos(b_lat) * cos(a_lat) * sin((a_lon - b_lon) / 2)^2
    return 2 * RADIUS_OF_EARTH_KM * asin(sqrt(d))
end

"""
    euclidean(A::Vector{GeoLocation}, B::Vector{GeoLocation})::Vector{AbstractFloat}

Calculates the euclidean distance (km) between two points.
"""
function euclidean(A::Vector{GeoLocation}, B::Vector{GeoLocation})::Vector{AbstractFloat}
    A = to_cartesian(A)
    B = to_cartesian(B)
    return sqrt.(sum.(eachrow((A - B).^2)))
end

euclidean(a::GeoLocation, b::GeoLocation)::AbstractFloat = euclidean([a], [b])[1]
euclidean(A::Vector{<:Node}, B::Vector{<:Node})::Vector{AbstractFloat} = euclidean([n.location for n in A], [n.location for n in B])
euclidean(a::Node, b::Node)::AbstractFloat = euclidean([a], [b])[1]

function euclidean(a::Vector{U}, b::Vector{U})::U where {U <: AbstractFloat}
    a_lat = deg2rad(a[1])
    a_lon = deg2rad(a[2])
    b_lat = deg2rad(b[1])
    b_lon = deg2rad(b[2])

    a_x = RADIUS_OF_EARTH_KM * cos(a_lat) * cos(a_lon)
    a_y = RADIUS_OF_EARTH_KM * cos(a_lat) * sin(a_lon)
    a_z = RADIUS_OF_EARTH_KM * sin(a_lat)

    b_x = RADIUS_OF_EARTH_KM * cos(b_lat) * cos(b_lon)
    b_y = RADIUS_OF_EARTH_KM * cos(b_lat) * sin(b_lon)
    b_z = RADIUS_OF_EARTH_KM * sin(b_lat)
    
    return sqrt(sum(([a_x, a_y, a_z] - [b_x, b_y, b_z]).^2))
end

"""
    distance(A::Union{Vector{GeoLocation}, GeoLocation, Vector{<:Node}, Node, Vector{<:AbstractFloat}},
             B::Union{Vector{GeoLocation}, GeoLocation, Vector{<:Node}, Node, Vector{<:AbstractFloat}},
             type::Symbol=:haversine
             )::Union{Vector{AbstractFloat}, AbstractFloat}

Calculates the distance (km) between two points or two vectors of points.

# Arguments
- `A::Union{Vector{GeoLocation}, GeoLocation, Vector{<:Node}, Node, Vector{<:AbstractFloat}}`: Vector of origin points.
- `B::Union{Vector{GeoLocation}, GeoLocation, Vector{<:Node}, Node, Vector{<:AbstractFloat}}`: Vector of destination points.
- `method::Symbol=:haversine`: Either `:haversine` or `:euclidean`.

# Return
- `Union{Vector{AbstractFloat}, AbstractFloat}`: Distance between origin and destination points in km.
"""
function distance(A::Union{Vector{GeoLocation},GeoLocation,Vector{<:Node},Node,Vector{<:AbstractFloat}},
                  B::Union{Vector{GeoLocation},GeoLocation,Vector{<:Node},Node,Vector{<:AbstractFloat}},
                  method::Symbol=:haversine
                  )::Union{Vector{AbstractFloat},AbstractFloat}
    if method == :haversine
        return haversine(A, B)
    elseif method == :euclidean
        return euclidean(A, B)
    else
        throw(ErrorException("Distance method $method not implemented"))
    end
end

"""
    function heading(A::Vector{GeoLocation}, B::Vector{GeoLocation}, return_units::Symbol=:degrees)::Vector{AbstractFloat}

Calculates headings / bearings between a vector of origin GeoLocations A and vector of destination 
GeoLocations B. Depending on the `return_units` chosen, the return angle is in range of [-π, π] if `:radians` or 
[-180, 180] if `:degrees`. Additionally, adjusts destination longitude in case the straight line path between A and B 
crosses the International Date Line.

# Arguments
- `A::Vector{GeoLocation}`: Vector of origin GeoLocations.
- `B::Vector{GeoLocation}`: Vector of destination GeoLocations.
- `return_units::Symbol=:degrees`: Either `:radians` or `:degrees`.

# Return
- `Vector{AbstractFloat}`: Vector of headings / bearings in range of [-π, π] if `:radians` or [-180, 180] if `:degrees`.
"""
function heading(A::Vector{GeoLocation}, B::Vector{GeoLocation}, return_units::Symbol=:degrees)::Vector{AbstractFloat}
    A = to_matrix(A)
    B = to_matrix(B)

    a_lat = A[:,1]
    a_lon = A[:,2]
    b_lat = B[:,1]
    b_lon = B[:,2]

    # Adjust destination longitude in case straight line path between A and B crosses the International Date Line
    a_lon_left_idx = (b_lon .<= a_lon) .* ((b_lon .+ 180) .+ (180 .- a_lon) .> (a_lon .- b_lon))
    a_lon_right_idx = (b_lon .<= a_lon) .* ((b_lon .+ 180) .+ (180 .- a_lon) .<= (a_lon .- b_lon))

    b_lon_left_idx = (b_lon .> a_lon) .* ((a_lon .+ 180) .+ (180 .- b_lon) .< (b_lon .- a_lon))
    b_lon_right_idx = (b_lon .> a_lon) .* ((a_lon .+ 180) .+ (180 .- b_lon) .>= (b_lon .- a_lon))

    b_lon_fixed = b_lon_left_idx .* (-180 .- (180 .- b_lon)) .+
                  b_lon_right_idx .* b_lon .+
                  a_lon_left_idx .* b_lon .+
                  a_lon_right_idx .* (180 .- abs.(-180 .- b_lon))

    a_lat = deg2rad.(a_lat)
    a_lon = deg2rad.(a_lon)
    b_lat = deg2rad.(b_lat)
    b_lon_fixed = deg2rad.(b_lon_fixed)

    y = sin.(b_lon_fixed - a_lon) .* cos.(b_lat)
    x = cos.(a_lat) .* sin.(b_lat) .- sin.(a_lat) .* cos.(b_lat) .* cos.(b_lon_fixed - a_lon)
    
    heading = atan.(y, x)

    if return_units == :radians
        return heading
    elseif return_units == :degrees
        return rad2deg.(heading)
    else
        throw(ErrorException("Incorrect input for argument `return_units`, choose either `:degrees` or `:radians`"))
end
end

heading(a::GeoLocation, b::GeoLocation, return_units::Symbol=:degrees)::AbstractFloat = heading([a], [b], return_units)[1]
heading(A::Vector{<:Node}, B::Vector{<:Node})::Vector{AbstractFloat} = heading([n.location for n in A], [n.location for n in B])
heading(a::Node, b::Node)::AbstractFloat = heading([a], [b])[1]

"""
    calculate_location(lats::Vector{<:Number},
                       lons::Vector{<:Number},
                       headings::Vector{<:Number},
                       distances::Vector{<:Number}
                       )::Vector{NamedTuple}

Calculates next location given origin Geolocations (lats, lons), headings (degrees) and distances (km).

# Arguments
- `origins::Vector{GeoLocation}`: Vector of origin GeoLocations (lats, lons).
- `headings::Vector{<:Number}`: Vector of headings to next location (degrees).
- `distances::Vector{<:Number}`: Vector of distances to next location (km).

# Return
- `Vector{GeoLocation}`: Vector of GeoLocations (lats, lons) of next locations.
"""
function calculate_location(origins::Vector{GeoLocation},
                            headings::Vector{<:Number},
                            distances::Vector{<:Number}
                            )::Vector{GeoLocation}
    origins = to_matrix(origins)

    lats = deg2rad.(origins[:,1])
    lons = deg2rad.(origins[:,2])
    headings = deg2rad.(headings)

    lats_final = asin.(sin.(lats) .* cos.(distances / RADIUS_OF_EARTH_KM) + cos.(lats) .* sin.(distances / RADIUS_OF_EARTH_KM) .* cos.(headings))
    lons_final = lons .+ atan.(sin.(headings) .* sin.(distances / RADIUS_OF_EARTH_KM) .* cos.(lats), cos.(distances / RADIUS_OF_EARTH_KM) - sin.(lats) .* sin.(lats_final))
    
    return GeoLocation([[loc...] for loc in zip(rad2deg.(lats_final), rad2deg.(lons_final))])
end

calculate_location(origin::GeoLocation, heading::Number, distance::Number)::GeoLocation = calculate_location([origin], [heading], [distance])[1]
calculate_location(origin::Vector{<:Node}, heading::Vector{<:Number}, distance::Vector{<:Number})::Vector{GeoLocation} = calculate_location([n.location for n in origin], heading, distance)
calculate_location(origin::Node, heading::Number, distance::Number)::GeoLocation = calculate_location([origin], [heading], [distance])[1]

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
