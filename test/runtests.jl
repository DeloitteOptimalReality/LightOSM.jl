using JSON
using LightOSM
using LightXML
using Test

@testset "LightOSM Tests" begin
    @testset "Utilities" begin include("utilities.jl") end
    @testset "Geometry" begin include("geometry.jl") end
    @testset "Download" begin include("download.jl") end
    @testset "Graph" begin include("graph.jl") end
end

