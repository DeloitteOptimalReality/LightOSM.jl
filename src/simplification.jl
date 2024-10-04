
#adapted from osmnx: https://github.com/gboeing/osmnx/blob/main/osmnx/simplification.py

"""
Predicate wether v is an edge endpoint in the simplified version of g
"""
function is_endpoint(g::AbstractGraph, v)
    neighbors = all_neighbors(g, v)
    if v in neighbors # has self loop
        return true
    elseif outdegree(g, v) == 0 || indegree(g, v) == 0 # sink or source
        return true
    elseif length(neighbors) != 2 || indegree(g, v) != outdegree(g, v) # change to/from one way
        return true
    end
    return false
end

"""
iterator over all endpoints in g
"""
endpoints(g::AbstractGraph) = (v for v in vertices(g) if is_endpoint(g, v))

"""
iterator over all paths in g which can be contracted
"""
function paths_to_reduce(g::AbstractGraph)
    (path_to_endpoint(g, (u, v)) for u in endpoints(g) for v in outneighbors(g, u))
end

"""
path to the next endpoint starting in edge (ep, ep_succ)
"""
function path_to_endpoint(g::AbstractGraph, (ep, ep_succ)::Tuple{T,T}) where {T<:Integer}
    path = [ep, ep_succ]
    head = ep_succ
    # ep_succ not in endpoints -> has 2 neighbors and degree 2 or 4
    while !is_endpoint(g, head)
        neighbors = [n for n in outneighbors(g, head) if n != path[end-1]]
        @assert length(neighbors) == 1 "found unmarked endpoint!"
        head, = neighbors
        push!(path, head)
        (head == ep) && return path # self loop
    end
    return path
end

"""
Return the total weight of a path given as a Vector of Ids.
"""
function total_weight(g::OSMGraph, path::Vector{<:Integer})
    sum((g.weights[path[[i, i+1]]...] for i in 1:length(path)-1))
end

function ways_in_path(g::OSMGraph, path::Vector{<:Integer})
    ways = Set{Int}()
    for i in 1:(length(path)-1)
        edge = [g.index_to_node[path[i]], g.index_to_node[path[i+1]]]
        push!(ways, g.edge_to_way[edge])
    end
    return collect(ways)
end

"""
Build a new graph which simplifies the topology of osmg.graph.
The resulting graph only contains intersections and dead ends from the original graph.
The geometry of the contracted nodes is kept in the edge_gdf DataFrame
"""
function simplify_graph(osmg::OSMGraph{U, T, W}) where {U, T, W}
    g = osmg.graph
    relevant_nodes = collect(endpoints(g))
    n_relevant = length(relevant_nodes)
    graph = DiGraph(n_relevant) 
    weights = similar(osmg.weights, (n_relevant, n_relevant))
    node_coordinates = Vector{Vector{W}}(undef, n_relevant)
    node_to_index = OrderedDict{T,U}()
    index_to_node = OrderedDict{U,T}()

    index_mapping = Dict{U,U}()
    for (new_i, old_i) in enumerate(relevant_nodes)
        index_mapping[old_i] = new_i
        node_coordinates[new_i] = osmg.node_coordinates[old_i]
        node = osmg.index_to_node[old_i]
        index_to_node[new_i] = node
        node_to_index[node] = new_i
    end

    edges = Dict{NTuple{3,U}, Vector{U}}()
    edge_count = Dict{Tuple{U,U}, Int}()
    for path in paths_to_reduce(g)
        u = index_mapping[first(path)]
        v = index_mapping[last(path)]
        path_weight = total_weight(osmg, path)
        if add_edge!(graph, (u, v))
            key = 0
            weights[u, v] = path_weight
            edge_count[u,v] = 1
        else # parallel edge
            key = edge_count[u,v]
            edge_count[u,v] += 1
            weights[u, v] = min(path_weight, weights[u, v])
        end
        edges[u,v,key] = path
    end

    edge_to_way = Dict{NTuple{3,U}, Vector{T}}()
    for (edge, path) in edges
        edge_to_way[edge] = ways_in_path(osmg, path)
    end

    return SimplifiedOSMGraph(
                osmg,
                node_coordinates,
                node_to_index,
                index_to_node,
                edge_to_way,
                graph,
                edges,
                weights,
                nothing
            )
end
