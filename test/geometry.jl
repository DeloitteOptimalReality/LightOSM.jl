a1 = GeoLocation(-33.8308, 151.223, 0.0)
a2 = GeoLocation(-33.8293, 151.221, 0.0)
A = [a1, a2]
b1 = GeoLocation(-33.8294, 150.22, 0.0)
b2 = GeoLocation(-33.8301, 151.22, 0.0)
B = [b1, b2]
node_a1 = Node(1,a1,nothing)
node_a2 = Node(1,a2,nothing)
node_b1 = Node(1,b1,nothing)
node_b2 = Node(1,b2,nothing)

@testset "Distance tests" begin
    @test isapprox(LightOSM.euclidean(a1, b1), 92.6448020780204)
    @test all(isapprox.(LightOSM.euclidean(A, B), [92.6448020780204, 0.1282389369277561]))
    @test isapprox(LightOSM.haversine(a1, b1), 92.64561837286445)
    @test all(isapprox.(LightOSM.haversine(A, B), [92.64561837286445, 0.1282389369295829]))
    @test LightOSM.euclidean(a1, b1) == LightOSM.euclidean(node_a1, node_b1)
    @test LightOSM.euclidean(A, B) == LightOSM.euclidean([node_a1, node_a2], [node_b1, node_b2])
    @test LightOSM.haversine(a1, b1) == LightOSM.haversine(node_a1, node_b1)
    @test LightOSM.haversine(A, B) == LightOSM.haversine([node_a1, node_a2], [node_b1, node_b2])
    @test LightOSM.euclidean([a1.lat, a1.lon], [b1.lat, b1.lon]) == LightOSM.euclidean(node_a1, node_b1)
    @test LightOSM.haversine([a1.lat, a1.lon], [b1.lat, b1.lon]) == LightOSM.haversine(node_a1, node_b1)

    @test isapprox(distance(a1, b1, :euclidean), 92.6448020780204)
    @test isapprox(distance(a1, b1, :haversine), 92.64561837286445)
    @test all(isapprox.(distance(A, B, :euclidean), [92.6448020780204, 0.1282389369277561]))
    @test all(isapprox.(distance(A, B, :haversine), [92.64561837286445, 0.1282389369295829]))
    @test_throws ArgumentError distance(a1, b1, :unknown_method)
end

@testset "Heading tests" begin
    a = GeoLocation(-33.8308, 151.223, 0.0)
    b = GeoLocation(-33.8294, 151.22, 0.0)
    # Used http://instantglobe.com/CRANES/GeoCoordTool.html to manually calculate headings and distance
    # Note: heading function returns bearings in range of [-180, 180], to convert to [0, 360] scale we need to adjust by (θ + 360) % 360
    @test abs((heading(a, b, :degrees) + 360) % 360 - 299.32559505087795) < 0.01
    @test sum((abs.(heading(A, B, :degrees) .+ 360) .% 360 - [299.32559505087795, 226.07812206538435])) < 0.01

    # Node methods
    @test heading(A, B, :degrees) == heading([node_a1, node_a2], [node_b1, node_b2], :degrees)

    # Radians
    @test isapprox(heading(a, b, :radians), deg2rad(heading(a, b, :degrees)))

    # Error handling
    @test_throws ArgumentError heading(a, b, :unknown_units)
end

@testset "calculate_location tests" begin
    a = GeoLocation(-33.8308, 151.223, 0.0)
    b = GeoLocation(-33.8294, 151.22, 0.0)
    dist_a = 100.0
    dist_b = 100.0
    heading_a = 10.0
    heading_b = 10.0
    end_a = calculate_location(a, heading_a, dist_a)
    @test isapprox(end_a.lat, -32.945001009035984)
    @test isapprox(end_a.lon, 151.40908284685628)
    @test isapprox(end_a.alt, 0.0)
    ends = calculate_location([a, b], [heading_a, heading_b], [dist_a, dist_b])
    @test ends[1] == end_a

    @test calculate_location(a, heading_a, 0.0) == a
    
    # Node methods
    node_a = Node(1, a, Dict{String, Any}())
    node_b = Node(1, b, Dict{String, Any}())
    @test calculate_location([a, b], [heading_a, heading_b], [dist_a, dist_b]) == calculate_location([node_a, node_b], [heading_a, heading_b], [dist_a, dist_b])
end

@testset "nearest_point_on_line tests" begin
    # Matching middle of line
    x, y, pos = LightOSM.nearest_point_on_line(
        1.0, 1.0,
        2.0, 2.0,
        2.0, 1.0
    )
    @test x ≈ 1.5
    @test y ≈ 1.5
    @test pos ≈ 0.5
    # Matching start of line
    x, y, pos = LightOSM.nearest_point_on_line(
        1.0, 1.0,
        2.0, 2.0,
        0.0, 1.0
    )
    @test x ≈ 1.0
    @test y ≈ 1.0
    @test pos ≈ 0.0
    # Matching end of line
    x, y, pos = LightOSM.nearest_point_on_line(
        1.0, 1.0,
        2.0, 2.0,
        3.0, 4.0
    )
    @test x ≈ 2.0
    @test y ≈ 2.0
    @test pos ≈ 1.0
end
