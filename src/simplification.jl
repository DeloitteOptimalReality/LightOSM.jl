
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
    elseif length(neighbors) != 2 || indegree(g, v) != outdegree(g, v) # change to one way
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

function total_weight(g::OSMGraph, path::Vector{<:Integer})
    sum((g.weights[path[[i, i+1]]...] for i in 1:length(path)-1))
end
"""
Build a new graph which simplifies the topology of osmg.graph.
The resulting graph only contains intersections and dead ends from the original graph.
The geometry of the contracted nodes is kept in the edge_gdf DataFrame
"""
function simplify_graph(osmg::OSMGraph)
    g = osmg.graph
    relevant_nodes = collect(endpoints(g))
    n = length(relevant_nodes)
    (n == nv(g)) && return g # nothing to simplify here


    G_simplified = DiGraph(n) 
    weights = similar(osmg.weights, (n, n))
    edge_gdf = DataFrame(
        u = Int[],
        v = Int[],
        key = Int[],
        weight = Vector{eltype(osmg.weights)}(),
        geom = IGeometry[],
    )
    node_gdf = DataFrame(id = Int[], geom = IGeometry[])


    index_mapping = Dict{Int,Int}()
    for (new_i, old_i) in enumerate(relevant_nodes)
        index_mapping[old_i] = new_i
        geo = createpoint(osmg.node_coordinates[old_i])
        push!(node_gdf, (new_i, geo))
    end

    for path in paths_to_reduce(g)
        u = index_mapping[first(path)]
        v = index_mapping[last(path)]
        path_weight = total_weight(osmg, path)
        geo = createlinestring(osmg.node_coordinates[path])

        if add_edge!(G_simplified, (u, v))
            key = 0
            weights[u, v] = path_weight
        else # parallel edge
            key = sum((edge_gdf.u .== u) .& (edge_gdf.v .== v))
            weights[u, v] = min(path_weight, weights[u, v])
        end
        push!(edge_gdf, (u, v, key, path_weight, geo))
    end

    return G_simplified, weights, node_gdf, edge_gdf
end
