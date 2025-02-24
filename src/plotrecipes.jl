function aspect_ratio(g::AbstractOSMGraph) 
    max_y, min_y = extrema(first, g.node_coordinates)
    mid_y = (max_y + min_y)/2
    return 1/cos(mid_y * pi/180)
end

RecipesBase.@recipe function f(g::AbstractOSMGraph)
    # set the aspect ratio
    aspect_ratio --> aspect_ratio(g)

    # way color and thickness
    color --> :black
    linewdith --> 1.5
    # node color and size
    markercolor --> :blue
    markersize --> 2

    # plot ways
    @series begin
        seriestype := :path
        MultiLineString(way_gdf(g).geom)
    end

    # plot nodes
    @series begin
        seriestype := :scatter
        node_gdf(g).geom
    end
end