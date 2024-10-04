Point(node::Node) = Point(node.location.lon, node.location.lat)
LineString(g::AbstractOSMGraph, way::Way) = LineString(Point.(g.parent.nodes[i] for i in way.nodes))

function node_gdf(g::AbstractOSMGraph)
    ids = collect(keys(g.nodes))
    nodes = (g.nodes[id] for id in ids)
    return DataFrame(;id=ids, tags=getproperty.(nodes, :tags), geom=Point.(nodes))
end

function way_gdf(g::AbstractOSMGraph)
    ids = collect(keys(g.ways))
    ways = (g.ways[id] for id in ids)
    return DataFrame(;id=ids, tags=getproperty.(ways, :tags), geom=LineString.(Ref(g), ways))
end

function edge_gdf(g::SimplifiedOSMGraph)
    edge_ids = collect(keys(g.edges))
    geom = map(edge_ids) do edge
        path = g.edges[edge]
        LineString(Point.(g.nodes[path]))
    end
    u, v, key = map(i -> getindex.(edge_ids, i), 1:3)
    return DataFrame(;u, v, key, geom=geom)
end