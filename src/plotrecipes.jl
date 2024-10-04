function aspect_ratio(g::AbstractOSMGraph) 
    max_y, min_y = extrema(first, g.node_coordinates)
    mid_y = (max_y + min_y)/2
    return 1/cos(mid_y * pi/180)
end

RecipesBase.@recipe function f(g::AbstractOSMGraph)
    color --> :black
    aspect_ratio --> aspect_ratio(g)
    MultiLineString(GeoInterface.coordinates.(highway_gdf(g).geom))
end