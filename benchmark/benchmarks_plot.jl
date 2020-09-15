using Plots
using DataFrames
using JSON
using LightOSM
using DataStructures

results = JSON.parsefile(joinpath(@__DIR__, "benchmark_results.json"))

time_units_mapping = Dict(
    "s" => 1,
    "ms" => 1e-3,
    "μs" => 1e-9
)

memory_units_mapping = Dict(
    "MiB" => 1,
    "KiB" => 1e-3,
    "GiB" => 1e+3,
)

df_dict_display = DefaultDict(Dict)
df_dict_time = DefaultDict(Dict)
df_dict_memory = DefaultDict(Dict)

for (algorithm, r) in results
    n_paths = collect(keys(r))
    n_paths_numeric = parse.(Float64, n_paths)

    df_dict_display[algorithm] = DefaultDict(Any[], "No. Paths" => n_paths)
    df_dict_time[algorithm] = DefaultDict(Number[], "No. Paths" => n_paths_numeric)
    df_dict_memory[algorithm] = DefaultDict(Number[], "No. Paths" => n_paths_numeric)

    for (n, packages) in r
        for (p, items) in packages
            mean_time = items["mean time"]
            gc_match = match(r"\((.*?)\)", mean_time)
            gc = LightOSM.remove_non_numeric(gc_match[1]) # %
            mean_time = replace(mean_time, gc_match.match => "")
            mean_time_units = strip(LightOSM.remove_numeric(mean_time))
            mean_time_units_factor = time_units_mapping[mean_time_units]
            mean_time = LightOSM.remove_non_numeric(mean_time) * mean_time_units_factor # s

            allocs = items["allocs estimate"]
            allocs = LightOSM.remove_non_numeric(allocs)

            memory = items["memory estimate"]
            memory_units = strip(LightOSM.remove_numeric(memory))
            memory_units_factor = memory_units_mapping[memory_units]
            memory = LightOSM.remove_non_numeric(memory) * memory_units_factor # MiB

            metrics = "$(round(mean_time, digits=4))s ($(round(memory, digits=2)) MiB)"
            push!(df_dict_display[algorithm][p], metrics)
            push!(df_dict_time[algorithm][p], mean_time)
            push!(df_dict_memory[algorithm][p], memory)
            
        end
    end
end

# Summary Tables
dijkstra_results = DataFrame(;[Symbol(k) => v for (k, v) in df_dict_display["dijkstra"]]...)
sort!(dijkstra_results, "No. Paths")
dijkstra_results = dijkstra_results[:, [Symbol("No. Paths"), :losm, :losm_precompute, :osmx, :lg]]
astar_results = DataFrame(;[Symbol(k) => v for (k, v) in df_dict_display["astar"]]...)
sort!(astar_results, "No. Paths")
astar_results = astar_results[:, [Symbol("No. Paths"), :losm, :losm_precompute, :osmx, :lg]]

# Dijsktra Time Comparison
dijkstra_df_time = DataFrame(;[Symbol(k) => v for (k, v) in df_dict_time["dijkstra"]]...)
sort!(dijkstra_df_time, "No. Paths")

dijkstra_time_x = dijkstra_df_time["No. Paths"]
dijkstra_time_y = Matrix(select!(dijkstra_df_time, Not(Symbol("No. Paths"))))
dijkstra_time_labels = permutedims(names(dijkstra_df_time))
plot_dijkstra_time() = plot(dijkstra_time_x, dijkstra_time_y, title="Dijkstra Shortest Path - Runtime (s) vs. No. Paths", label=dijkstra_time_labels, ylabel="Runtime (s)", xlabel="No. Paths", lw=3, fmt=:png)

# Dijsktra Memory Comparison
dijkstra_df_memory = DataFrame(;[Symbol(k) => v for (k, v) in df_dict_memory["dijkstra"]]...)
sort!(dijkstra_df_memory, "No. Paths")

dijkstra_memory_x = dijkstra_df_memory["No. Paths"]
dijkstra_memory_y = Matrix(select!(dijkstra_df_memory, Not(Symbol("No. Paths"))))
dijkstra_memory_labels = permutedims(names(dijkstra_df_memory))
plot_dijkstra_memory() = plot(dijkstra_memory_x, dijkstra_memory_y, title="Dijkstra Shortest Path - Memory (MiB) vs. No. Paths", label=dijkstra_memory_labels, ylabel="Memory (MiB)", xlabel="No. Paths", lw=3, fmt=:png)

# A* Time Comparison
astar_df_time = DataFrame(;[Symbol(k) => v for (k, v) in df_dict_time["astar"]]...)
sort!(astar_df_time, "No. Paths")

astar_time_x = astar_df_time["No. Paths"]
astar_time_y = Matrix(select!(astar_df_time, Not(Symbol("No. Paths"))))
astar_time_labels = permutedims(names(astar_df_time))
plot_astar_time() = plot(astar_time_x, astar_time_y, title="A* Shortest Path - Runtime (s) vs. No. Paths", label=astar_time_labels, ylabel="Runtime (s)", xlabel="No. Paths", lw=3, fmt=:png)

# A* Memory Comparison
astar_df_memory = DataFrame(;[Symbol(k) => v for (k, v) in df_dict_memory["astar"]]...)
sort!(astar_df_memory, "No. Paths")

astar_memory_x = astar_df_memory["No. Paths"]
astar_memory_y = Matrix(select!(astar_df_memory, Not(Symbol("No. Paths"))))
astar_memory_labels = permutedims(names(astar_df_memory))
plot_astar_memory() = plot(astar_memory_x, astar_memory_y, title="A* Shortest Path - Memory (MiB) vs. No. Paths", label=astar_memory_labels, ylabel="Memory (MiB)", xlabel="No. Paths", lw=3, fmt=:png)