@testset "Downloader selection" begin
    @test LightOSM.osm_network_downloader(:place_name) == LightOSM.osm_network_from_place_name
    @test LightOSM.osm_network_downloader(:bbox) == LightOSM.osm_network_from_bbox
    @test LightOSM.osm_network_downloader(:point) == LightOSM.osm_network_from_point
    @test LightOSM.osm_network_downloader(:polygon) == LightOSM.osm_network_from_polygon
    @test_throws ArgumentError LightOSM.osm_network_downloader(:doesnt_exist)
end

function wait_for_overpass()
    count = 0
    while !LightOSM.is_overpass_server_availabile()
        count == 7 && break # Can't wait indefinitely, and the failure will be caught in the tests
        count += 1
        @info "Waiting for overpass server..."
        sleep(5 * count)
    end
end

@testset "Downloads" begin
    filenames = ["map.osm", "map.json"]
    formats = [:osm, :json]
    for (filename, format) in zip(filenames, formats)
        try
            wait_for_overpass()
            data = download_osm_network(:point,
                                        radius=0.5,
                                        point=GeoLocation(-37.8136, 144.9631),
                                        network_type=:drive,
                                        download_format=format,
                                        save_to_file_location=filename);
            @test isfile(filename)
            g = graph_from_file(filename) # Check it doesn't error
        catch err
            # Sometimes gets HTTP.ExceptionRequest.StatusError in tests due to connection to overpass
            !isa(err, HTTP.ExceptionRequest.StatusError) && rethrow()
            @error "Test failed due to connection issue" exception=(err, catch_backtrace())
        end

        try
            rm(filename)
        catch
        end
    end
end