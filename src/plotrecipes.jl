function aspect_ratio(g::OSMGraph) 
    max_y, min_y = extrema(first, g.node_coordinates)
    mid_y = (max_y + min_y)/2
    return 1/cos(mid_y * pi/180)
end
aspect_ratio(sg::SimplifiedOSMGraph) = aspect_ratio(sg.parent)


RecipesBase.@recipe function f(g::AbstractOSMGraph)
    color --> :black
    aspect_ratio --> aspect_ratio(g)
    MultiLineString(GeoInterface.coordinates.(highway_gdf(g).geom))
end