g = basic_osm_graph_stub()

@testset "GeoLocation tests" begin
    ep = LightOSM.EdgePoint(1003, 1004, 0.4)
    expected_response = GeoLocation(lon=145.3326838, lat=-38.0754037)
    actual_response = GeoLocation(g, ep)
    @test expected_response ≈ actual_response
end
