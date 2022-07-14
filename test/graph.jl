g = basic_osm_graph_stub()

@testset "Backwards compatibility" begin
    @test g.ways === g.ways
    @test g.node_to_way === g.node_to_way
    @test g.edge_to_way === g.edge_to_way
end