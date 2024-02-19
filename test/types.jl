g_int = basic_osm_graph_stub()
g_str = basic_osm_graph_stub_string()
@testset "GeoLocation tests integer" begin
    # Testing for int graph
    ep = LightOSM.EdgePoint(1003, 1004, 0.4)
    expected_response = GeoLocation(lon=145.3326838, lat=-38.0754037)
    actual_response = GeoLocation(g_int, ep)
    @test expected_response ≈ actual_response

    #Testing for str graph
    ep = LightOSM.EdgePoint("1003", "1004", 0.4)
    expected_response = GeoLocation(lon=145.3326838, lat=-38.0754037)
    actual_response = GeoLocation(g_str, ep)
    @test expected_response ≈ actual_response
end