GeometryBasics.Point(node::Node) = Point(node.location.lon, node.location.lat)
GeometryBasics.LineString(way::Way) = LineString(Point.(way.nodes))

function node_gdf(g::AbstractOSMGraph)
    ids = collect(keys(g.nodes))
    return DataFrame(;id=ids, geom=Point.(values(g.nodes)))
end

function way_gdf(g::AbstractOSMGraph)
    ids = collect(keys(g.ways))
    return DataFrame(;id=ids, geom=LineString.(values(g.ways)))
end

function edge_gdf(g::SimplifiedOSMGraph)
    edge_ids = collect(keys(g.edges))
    geom = map(edge_ids) do edge
        path = g.edges[edge]
        reverse.(g.parent.node_coordinates[path])
    end
    u, v, key = map(i -> getindex.(edge_ids, i), 1:3)
    return DataFrame(;u, v, key, geom=LineString.(geom))
end