@testset "concatenate_exclusions tests" begin 
    dict = Dict(
        "first" => ["single"],
        "second" => ["dual1", "dual2"]
    )

    single_dict = Dict("first" => ["single"])
    single_str = LightOSM.concatenate_exclusions(single_dict)
    @test startswith(single_str, '[')
    @test endswith(single_str, ']')
    args_only = chop(single_str, head=1, tail=1)
    args = split(args_only, "!~")
    @test args[1] == "\"first\""
    @test args[2] == "\"single\""

    dual_dict = Dict("second" => ["dual1", "dual2"])
    dual_str = LightOSM.concatenate_exclusions(dual_dict)
    @test startswith(dual_str, '[')
    @test endswith(dual_str, ']')
    args_only = chop(dual_str, head=1, tail=1)
    args = split(args_only, "!~")
    @test args[1] == "\"second\""
    @test args[2] == "\"dual1|dual2\""

    combined_dict = dict = Dict(
        "first" => ["single"],
        "second" => ["dual1", "dual2"]
    )
    str = LightOSM.concatenate_exclusions(combined_dict)
    @test str == single_str * dual_str || str == dual_str * single_str # either order
end

@testset "set_defaults tests" begin
    resp = HTTP.get(TEST_OSM_URL)
    data = JSON.parse(String(resp.body))

    # Get original defaults
    original_maxspeeds = deepcopy(LightOSM.DEFAULT_MAXSPEEDS[])
    original_lanes = deepcopy(LightOSM.DEFAULT_LANES[])

    # Create graph using originals
    original_g = LightOSM.graph_from_object(deepcopy(data); graph_type=:static, weight_type=:lane_efficiency)

    # New defaults
    new_maxspeeds = Dict(
        "motorway" => 100,
        "trunk" => 100,
        "primary" => 60,
        "secondary" => 60,
        "tertiary" => 50,
        "unclassified" => 50,
        "residential" => 40,
        "other" => 50
    )
    new_lanes = Dict(
        "motorway" => 5,
        "trunk" => 4,
        "primary" => 3,
        "secondary" => 1,
        "tertiary" => 1,
        "unclassified" => 1,
        "residential" => 1,
        "other" => 1
    )
    LightOSM.set_defaults(
        maxspeeds=new_maxspeeds, 
        lanes=new_lanes
    )

    # Create graph using new values
    new_g = LightOSM.graph_from_object(deepcopy(data); graph_type=:static, weight_type=:lane_efficiency)

    # Test way 217499573, Chapel St with tags:
    # "highway": "secondary"
    # "name": "Chapel Street"
    # "surface": "asphalt"
    @test original_g.ways[217499573].tags["maxspeed"] == original_maxspeeds["secondary"]
    @test new_g.ways[217499573].tags["maxspeed"] == new_maxspeeds["secondary"]
    @test original_g.ways[217499573].tags["lanes"] == original_lanes["secondary"]
    @test new_g.ways[217499573].tags["lanes"] == new_lanes["secondary"]
end
