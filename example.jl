using LightOSM, Plots, GeoInterfaceRecipes
using StatsBase: sample

g = graph_from_download(
    :place_name, 
    place_name="tiergarten, berlin germany",
    network_type=:drive
)
sg = simplify_graph(g)

# Set plot size
size = (1920, 1080)

# Show original nodes
plot(g; size)
savefig("original_nodes")

# Show relevant nodes
plot(sg; size)
savefig("relevant_nodes")



osm_ids = sample(collect(values(sg.nodes)), 200)
for source in osm_ids
    for target in osm_ids
        path = shortest_path(g, source, target)
        path_simplified = shortest_path(sg, source, target)
        if isnothing(path) || isnothing(path_simplified)
            continue
        end
        path_length = total_path_weight(g, path)
        path_simplified_length = total_path_weight(sg, path_simplified)
        if !isapprox(path_length, path_simplified_length)
            error("Path from $source to $target is $path_length in the original graph and $path_simplified_length in the simplified graph")
        end
    end
end
