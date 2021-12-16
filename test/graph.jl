g = basic_osm_graph_stub()

@testset "Backwards compatibility" begin
    @test g.ways === g.highways
    @test g.node_to_way === g.node_to_highway
    @test g.edge_to_way === g.edge_to_highway
end