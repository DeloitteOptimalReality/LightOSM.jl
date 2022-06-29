g = basic_osm_graph_stub()

@testset "Subgraph" begin
    # Create a subgraph using all nodes/vertices from g for testing
    nlist = [n.id for n in values(g.nodes)]
    sg = osm_subgraph(g, nlist)
    @test get_graph_type(g) === :static
    @test sg.nodes == g.nodes
    @test sg.ways == g.ways
    @test sg.restrictions == g.restrictions
    @test sg.weight_type == g.weight_type
    @test isdefined(sg.dijkstra_states, 1) == isdefined(g.dijkstra_states, 1)
    if isdefined(g.dijkstra_states, 1)
        @test sg.dijkstra_states == g.dijkstra_states
    end
    @test isdefined(sg.kdtree, 1) == isdefined(g.kdtree, 1)
    if isdefined(g.kdtree, 1)
        @test typeof(sg.kdtree) == typeof(g.kdtree)
    end
end