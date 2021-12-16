using HTTP
using JSON
using LightOSM
using LightXML
using Test

include("stub.jl")

@testset "LightOSM Tests" begin
    @testset "Constants" begin include("constants.jl") end
    @testset "Utilities" begin include("utilities.jl") end
    @testset "Geometry" begin include("geometry.jl") end
    @testset "Download" begin include("download.jl") end
    @testset "Nearest Node" begin include("nearest_node.jl") end
    @testset "Shortest Path" begin include("shortest_path.jl") end
    @testset "Graph" begin include("graph.jl") end
end