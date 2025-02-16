@testset "parse empty osm file" begin 
    xml = LightXML.parse_file(joinpath(@__DIR__, "data", "empty.osm"))
    graph = graph_from_object(xml)
    @test isempty(graph.nodes)
end