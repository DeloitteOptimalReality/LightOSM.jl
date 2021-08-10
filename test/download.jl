@testset "Downloader selection" begin
    @test LightOSM.osm_network_downloader(:place_name) == LightOSM.osm_network_from_place_name
    @test LightOSM.osm_network_downloader(:bbox) == LightOSM.osm_network_from_bbox
    @test LightOSM.osm_network_downloader(:point) == LightOSM.osm_network_from_point
    @test LightOSM.osm_network_downloader(:polygon) == LightOSM.osm_network_from_polygon
    @test_throws ArgumentError LightOSM.osm_network_downloader(:doesnt_exist)
end

@testset "Download end to end formats" begin
    # JSON
    filename = "melbourne_1k.json"
    wait_for_overpass()
    data = download_osm_network(:point,
                                radius=0.5,
                                point=GeoLocation(-37.8136, 144.9631),
                                network_type=:drive,
                                download_format=:json,
                                save_to_file_location=filename);
    @test isfile(filename)
    g = graph_from_file(filename) # Check it doesn't error
    rm(filename)

    # XML
    filename = "melbourne_1k.xml"
    wait_for_overpass()
    data = download_osm_network(:point,
                                radius=0.5,
                                point=GeoLocation(-37.8136, 144.9631),
                                network_type=:drive,
                                download_format=:xml,
                                save_to_file_location=filename);
    @test isfile(filename)
    g = graph_from_file(filename) # Check it doesn't error
    rm(filename)

    # OSM
    filename = "melbourne_1k.osm"
    wait_for_overpass()
    data = download_osm_network(:point,
                                radius=0.5,
                                point=GeoLocation(-37.8136, 144.9631),
                                network_type=:drive,
                                download_format=:osm,
                                save_to_file_location=filename);
    @test isfile(filename)
    g = graph_from_file(filename) # Check it doesn't error
    g_distance = graph_from_object(data, weight_type=:distance) # replace by better tests in future
    rm(filename)
end