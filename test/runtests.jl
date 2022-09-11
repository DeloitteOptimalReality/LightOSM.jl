using Graphs
using HTTP
using JSON
using LightOSM
using LightXML
using SparseArrays
using Random
using Test

include("stub.jl")

const TEST_OSM_URL = "https://raw.githubusercontent.com/DeloitteOptimalReality/LightOSMFiles.jl/main/maps/south-yarra.json"

@testset "LightOSM Tests" begin
    @testset "Constants" begin include("constants.jl") end
    @testset "Utilities" begin include("utilities.jl") end
    @testset "Geometry" begin include("geometry.jl") end
    @testset "Download" begin include("download.jl") end
    @testset "Nearest Node" begin include("nearest_node.jl") end
    @testset "Nearest Way" begin include("nearest_way.jl") end
    @testset "Shortest Path" begin include("shortest_path.jl") end
    @testset "Graph" begin include("graph.jl") end
    @testset "Traversal" begin include("traversal.jl") end
    @testset "Subgraph" begin include("subgraph.jl") end
end
