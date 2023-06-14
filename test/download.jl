@testset "Downloader selection" begin
    @test LightOSM.osm_network_downloader(:place_name) == LightOSM.osm_network_from_place_name
    @test LightOSM.osm_network_downloader(:bbox) == LightOSM.osm_network_from_bbox
    @test LightOSM.osm_network_downloader(:point) == LightOSM.osm_network_from_point
    @test LightOSM.osm_network_downloader(:polygon) == LightOSM.osm_network_from_polygon
    @test LightOSM.osm_network_downloader(:custom_filters) == LightOSM.osm_network_from_custom_filters
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
                save_to_file_location=filename)
            @test isfile(filename)
            g = graph_from_file(filename) # Check it doesn't error
        catch err
            # Sometimes gets HTTP.ExceptionRequest.StatusError in tests due to connection to overpass
            !isa(err, HTTP.ExceptionRequest.StatusError) && rethrow()
            @error "Test failed due to connection issue" exception = (err, catch_backtrace())
        end

        try
            rm(filename)
        catch
        end
    end
end

@testset "Download with custom filters" begin
    filename = "map.json"
    format = :json
    custom_filters = """
    way
        ["highway"]
        ["motorcar"!~"no"]
        ["area"!~"yes"]   
        ["highway"!~"elevator|steps|tertiary|construction|bridleway|proposed|track|pedestrian|secondary|path|living_street|cycleway|primary|footway|platform|abandoned|service|escalator|corridor|raceway"]
        ["motor_vehicle"!~"no"]["access"!~"private"]
        ["service"!~"parking|parking_aisle|driveway|private|emergency_access"]
    ;
    >
    ;
    """
    bbox = [-37.816779513558274, 144.9590750877158, -37.81042034950731, 144.967124565619]

    try
        wait_for_overpass()
        test_custom_query = download_osm_network(
            :custom_filters, 
            download_format=format,
            save_to_file_location=filename,
            custom_filters=custom_filters, 
            bbox = bbox
        )

        @test isfile(filename)
        g = graph_from_file(filename)
        for (_, way) in g.ways
            # Make sure Overpass excluded these tags, as they are excluded in the filter
            highway_tags_to_check = ["primary", "secondary", "tertiary", "living_street"]
            if haskey(way.tags, "highway")
                @test way.tags["highway"] ∉ highway_tags_to_check
            end
        end
    catch err
        # Sometimes gets HTTP.ExceptionRequest.StatusError in tests due to connection to overpass
        !isa(err, HTTP.ExceptionRequest.StatusError) && rethrow()
        @error "Test failed due to connection issue" exception = (err, catch_backtrace())
    end

    # Remove file after test
    try
        rm(filename)
    catch
    end
end