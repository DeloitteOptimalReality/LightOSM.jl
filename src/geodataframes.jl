coordinates(node::Node) = [node.location.lon, node.location.lat]

function node_gdf(g::OSMGraph)
    ids = collect(keys(g.nodes))
    geom = map(ids) do id
       coordinates(g.nodes[id])
    end
    return DataFrame(;id=ids, geom=Point.(geom))
end

function way_gdf(g::OSMGraph)
    ids = collect(keys(g.highways))
    _way_coordinates(way) = map(way.nodes) do id
        coordinates(g.nodes[id])
    end
    geom = map(id -> _way_coordinates(g.highways[id]), ids)
    return DataFrame(;id=ids, geom=LineString.(geom))
end

function node_gdf(sg::SimplifiedOSMGraph)
    ids = collect(keys(sg.node_to_index))
    geom = map(ids) do id
        coordinates(sg.parent.nodes[id])
    end
    return DataFrame(;id=ids, geom=Point.(geom))
end

way_gdf(sg::SimplifiedOSMGraph) = way_gdf(sg.parent)

function edge_gdf(sg::SimplifiedOSMGraph)
    edge_ids = collect(keys(sg.edges))
    geom = map(edge_ids) do edge
        path = sg.edges[edge]
        reverse.(sg.parent.node_coordinates[path])
    end
    u, v, key = map(i -> getindex.(edge_ids, i), 1:3)
    return DataFrame(;u, v, key, geom=LineString.(geom))
end