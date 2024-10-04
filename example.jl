using LightOSM, Plots

g = graph_from_download(
    :place_name, 
    place_name="tiergarten, berlin germany",
    network_type=:bike
)
sg = simplify_graph(g)

# check for missing edges
plot(g, color=:red, linewidth=0.8)
plot!(edge_gdf(sg).geom, linewidth=1.1, color=:black)
savefig("edge_validation")

# show original nodes
plot(sg)
plot!(node_gdf(g).geom, color=:red, markersize=2.2)
savefig("original_nodes")

# show relevant nodes
plot(sg)
plot!(node_gdf(sg).geom, color=:green, markersize=2.2)
savefig("relevant_nodes")