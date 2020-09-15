using Random
using BenchmarkTools
using LightOSM
using OpenStreetMapX
using LightGraphs
using DataStructures
using JSON

"""
Setup
"""

Random.seed!(1234) # Set seed so experiment is reproducible

point = GeoLocation(-37.8142176, 144.9631608) # Melbourne, Australia
radius = 5 # km
data_file = joinpath(@__DIR__, "benchmark_map.osm")

g_losm = LightOSM.graph_from_download(:point,
                                      point=point,
                                      radius=radius,
                                      weight_type=:distance,
                                      save_to_file_location=data_file)

# g_losm = LightOSM.graph_from_file(data_file, weight_type=:distance)
@time g_losm_precompute = LightOSM.graph_from_file(data_file, weight_type=:distance, precompute_dijkstra_states=true)

g_osmx = OpenStreetMapX.get_map_data(data_file,
                                     use_cache=false,
                                     only_intersections=false,
                                     trim_to_connected_graph=true)


"""
Define benchmark functions
"""

function losm_shortest_path(g::LightOSM.OSMGraph, o_d_nodes, algorithm)
    for (o, d) in o_d_nodes
        try
            LightOSM.shortest_path(g, o, d, algorithm=algorithm)
        catch
            # Error exception will be thrown if path does not exist from origin to destination node
        end
    end
end

function osmx_shortest_path(g::OpenStreetMapX.MapData, o_d_nodes, algorithm)
    for (o, d) in o_d_nodes
        try
            OpenStreetMapX.find_route(g, o, d, g.w, routing=algorithm, heuristic=(u, v) -> OpenStreetMapX.get_distance(u, v, g_osmx.nodes, g_osmx.n), get_distance=false, get_time=false)
        catch
            # Error exception will be thrown if path does not exist from origin to destination node
        end
    end
end

function lg_shortest_path(g::LightOSM.OSMGraph, o_d_indices, algorithm)
    if algorithm == :astar
        for (o, d) in o_d_indices
            try
                LightGraphs.a_star(g.graph, o, d, g.weights)
            catch
                # Error exception will be thrown if path does not exist from origin to destination node
            end
        end
    elseif algorithm == :dijkstra
        for (o, d) in o_d_indices
            try
                state = LightGraphs.dijkstra_shortest_paths(g.graph, o, g.weights)
                LightGraphs.enumerate_paths(state, d)
            catch
                # Error exception will be thrown if path does not exist from origin to destination node
            end
        end
    end
end

function extract(bmark_trial)
    io = IOBuffer()
    show(io, "text/plain", bmark_trial)

    s = String(take!(io))
    s = split.((split(s, "\n")), ":")

    result = Dict{String,String}()

    for item in s
        if length(item) >= 2
            result[strip(item[1])] = strip(item[2])
        end
    end
    @info "Extracted benchmark result: $result"
    return result
end

"""
Define experiment
"""

n_paths = [1, 10, 100, 1000, 10000]
o_d_indices = OrderedDict()
o_d_nodes = OrderedDict()

losm_nodes = collect(keys(g_losm.nodes))
osmx_nodes = collect(keys(g_osmx.nodes))
common_nodes = intersect(losm_nodes, osmx_nodes)

for n in n_paths
    rand_o_d_indices = rand(1:length(common_nodes), n, 2)
    o_d_indices[n] = [[o, d] for (o, d) in eachrow(rand_o_d_indices) if o != d]
    o_d_nodes[n] = [[common_nodes[o], common_nodes[d]] for (o, d) in eachrow(rand_o_d_indices) if o != d]
end

"""
Run experiment
"""
results = Dict(:dijkstra => DefaultDict(Dict), :astar => DefaultDict(Dict))

results[:dijkstra][1][:losm] = extract(@benchmark losm_shortest_path(g_losm, o_d_nodes[1], :dijkstra))
results[:dijkstra][1][:losm_precompute] = extract(@benchmark losm_shortest_path(g_losm_precompute, o_d_nodes[1], :dijkstra))
results[:dijkstra][1][:osmx] = extract(@benchmark osmx_shortest_path(g_osmx, o_d_nodes[1], :dijkstra))
results[:dijkstra][1][:lg] = extract(@benchmark lg_shortest_path(g_losm, o_d_indices[1], :dijkstra))

results[:dijkstra][10][:losm] = extract(@benchmark losm_shortest_path(g_losm, o_d_nodes[10], :dijkstra))
results[:dijkstra][10][:losm_precompute] = extract(@benchmark losm_shortest_path(g_losm_precompute, o_d_nodes[10], :dijkstra))
results[:dijkstra][10][:osmx] = extract(@benchmark osmx_shortest_path(g_osmx, o_d_nodes[10], :dijkstra))
results[:dijkstra][10][:lg] = extract(@benchmark lg_shortest_path(g_losm, o_d_indices[10], :dijkstra))

results[:dijkstra][100][:losm] = extract(@benchmark losm_shortest_path(g_losm, o_d_nodes[100], :dijkstra))
results[:dijkstra][100][:losm_precompute] = extract(@benchmark losm_shortest_path(g_losm_precompute, o_d_nodes[100], :dijkstra))
results[:dijkstra][100][:osmx] = extract(@benchmark osmx_shortest_path(g_osmx, o_d_nodes[100], :dijkstra))
results[:dijkstra][100][:lg] = extract(@benchmark lg_shortest_path(g_losm, o_d_indices[100], :dijkstra))

results[:dijkstra][1000][:losm] = extract(@benchmark losm_shortest_path(g_losm, o_d_nodes[1000], :dijkstra))
results[:dijkstra][1000][:losm_precompute] = extract(@benchmark losm_shortest_path(g_losm_precompute, o_d_nodes[1000], :dijkstra))
results[:dijkstra][1000][:osmx] = extract(@benchmark osmx_shortest_path(g_osmx, o_d_nodes[1000], :dijkstra))
results[:dijkstra][1000][:lg] = extract(@benchmark lg_shortest_path(g_losm, o_d_indices[1000], :dijkstra))

results[:dijkstra][10000][:losm] = extract(@benchmark losm_shortest_path(g_losm, o_d_nodes[10000], :dijkstra))
results[:dijkstra][10000][:losm_precompute] = extract(@benchmark losm_shortest_path(g_losm_precompute, o_d_nodes[10000], :dijkstra))
results[:dijkstra][10000][:osmx] = extract(@benchmark osmx_shortest_path(g_osmx, o_d_nodes[10000], :dijkstra))
results[:dijkstra][10000][:lg] = extract(@benchmark lg_shortest_path(g_losm, o_d_indices[10000], :dijkstra))

results[:astar][1][:losm] = extract(@benchmark losm_shortest_path(g_losm, o_d_nodes[1], :astar))
results[:astar][1][:losm_precompute] = extract(@benchmark losm_shortest_path(g_losm_precompute, o_d_nodes[1], :astar))
results[:astar][1][:osmx] = extract(@benchmark osmx_shortest_path(g_osmx, o_d_nodes[1], :astar))
results[:astar][1][:lg] = extract(@benchmark lg_shortest_path(g_losm, o_d_indices[1], :astar))

results[:astar][10][:losm] = extract(@benchmark losm_shortest_path(g_losm, o_d_nodes[10], :astar))
results[:astar][10][:losm_precompute] = extract(@benchmark losm_shortest_path(g_losm_precompute, o_d_nodes[10], :astar))
results[:astar][10][:osmx] = extract(@benchmark osmx_shortest_path(g_osmx, o_d_nodes[10], :astar))
results[:astar][10][:lg] = extract(@benchmark lg_shortest_path(g_losm, o_d_indices[10], :astar))

results[:astar][100][:losm] = extract(@benchmark losm_shortest_path(g_losm, o_d_nodes[100], :astar))
results[:astar][100][:losm_precompute] = extract(@benchmark losm_shortest_path(g_losm_precompute, o_d_nodes[100], :astar))
results[:astar][100][:osmx] = extract(@benchmark osmx_shortest_path(g_osmx, o_d_nodes[100], :astar))
results[:astar][100][:lg] = extract(@benchmark lg_shortest_path(g_losm, o_d_indices[100], :astar))

results[:astar][1000][:losm] = extract(@benchmark losm_shortest_path(g_losm, o_d_nodes[1000], :astar))
results[:astar][1000][:losm_precompute] = extract(@benchmark losm_shortest_path(g_losm_precompute, o_d_nodes[1000], :astar))
results[:astar][1000][:osmx] = extract(@benchmark osmx_shortest_path(g_osmx, o_d_nodes[1000], :astar))
results[:astar][1000][:lg] = extract(@benchmark lg_shortest_path(g_losm, o_d_indices[1000], :astar))

results[:astar][10000][:losm] = extract(@benchmark losm_shortest_path(g_losm, o_d_nodes[10000], :astar))
results[:astar][10000][:losm_precompute] = extract(@benchmark losm_shortest_path(g_losm_precompute, o_d_nodes[10000], :astar))
results[:astar][10000][:osmx] = extract(@benchmark osmx_shortest_path(g_osmx, o_d_nodes[10000], :astar))
results[:astar][10000][:lg] = extract(@benchmark lg_shortest_path(g_losm, o_d_indices[10000], :astar))

"""
Export Results
"""

open(joinpath(@__DIR__, "benchmark_results.json"), "w") do io
    write(io, json(results))
end