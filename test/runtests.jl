using JSON
using LightOSM
using LightXML
using Test

function wait_for_overpass()
    count = 0
    while !LightOSM.is_overpass_server_availabile()
        count == 6 && error("Overpass server is not available for tests")
        count += 1
        @info "Waiting for overpass server..."
        sleep(4 * count)
    end
end

@testset "LightOSM Tests" begin
    @testset "Constants" begin include("constants.jl") end
    @testset "Utilities" begin include("utilities.jl") end
    @testset "Geometry" begin include("geometry.jl") end
    @testset "Download" begin include("download.jl") end
    @testset "Graph" begin include("graph.jl") end
    @testset "Nearest Node" begin include("nearest_node.jl") end
end

