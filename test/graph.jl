graphs = [
    basic_osm_graph_stub_string(),
    basic_osm_graph_stub()
]
@testset "Backwards compatibility" begin
    for g in graphs
    @test g.ways === g.ways
    @test g.node_to_way === g.node_to_way
    @test g.edge_to_way === g.edge_to_way
    end
end
@testset "Regression test for railway lane parsing" begin
    g = graph_from_download(
        :place_name,
        place_name = "bern, switzerland",
        network_type = :rail,
        weight_type = :distance
    )
    _, way = rand(g.ways)
    @test way.tags["lanes"] isa Integer
end