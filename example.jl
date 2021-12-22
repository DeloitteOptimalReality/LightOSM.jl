using LightOSM, GeoInterface, Plots, DataFrames
using ArchGDAL: createmultilinestring

g = graph_from_download(
    :place_name, place_name="moabit, berlin germany",
    network_type=:bike
)
# reverse coordinates for plotting
reverse!.(g.node_coordinates)

g_simple, weights, node_gdf, edge_gdf = simplify_graph(g)

# join edges in mulitlinestring for faster plotting
all_edges = createmultilinestring(coordinates.(edge_gdf.geom))

# node validation

# nodes from original graph
plot(all_edges, color=:black, size=(1200,800))
scatter!(first.(g.node_coordinates), last.(g.node_coordinates), color=:red)

# nodes from simplified graph
plot(all_edges, color=:black, size=(1200,800))
scatter!(node_gdf.geom, color=:green)


# edge validation

function highway_gdf(osmg::OSMGraph)
    function _geometrize_way(way)
        createlinestring(map(id -> coordinates(osmg.nodes[id]), way.nodes))
    end
    geom = map(way -> _geometrize_way(way), values(osmg.highways))
    return DataFrame(; id = collect(keys(osmg.highways)), geom)
end

