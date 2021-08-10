using JSON
using LightOSM
using LightXML
using Test

function wait_for_overpass()
    count = 0
    while !LightOSM.is_overpass_server_availabile()
        count == 7 && error("Overpass server is not available for tests")
        count += 1
        @info "Waiting for overpass server..."
        sleep(5 * count)
    end
end

# OSM graph for all tests to use
filename = "melbourne_1k.osm"
wait_for_overpass()
data = download_osm_network(:point,
                            radius=0.5,
                            point=GeoLocation(-37.8136, 144.9631),
                            network_type=:drive,
                            download_format=:osm,
                            save_to_file_location=filename);
@test isfile(filename)
g_time = graph_from_file(filename) # Check it doesn't error
g_distance = graph_from_object(data, weight_type=:distance) # replace by better tests in future

@testset "LightOSM Tests" begin
    @testset "Constants" begin include("constants.jl") end
    @testset "Utilities" begin include("utilities.jl") end
    @testset "Geometry" begin include("geometry.jl") end
    @testset "Download" begin include("download.jl") end
    @testset "Nearest Node" begin include("nearest_node.jl") end
end

# Tidy up
rm(filename)