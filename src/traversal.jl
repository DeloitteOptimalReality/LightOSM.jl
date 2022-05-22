"""
    astar(g::AbstractGraph{U},
          weights::AbstractMatrix{T},
          src::W,
          goal::W;
          heuristic::Function=(u, v) ->  0.0,
          cost_adjustment::Function=(u, v, parents) -> 0.0
          ) where {T <: Real, U <: Integer, W <: Integer}

A* shortest path algorithm. Implemented with a min heap. Using a min heap is faster than using 
a priority queue given the sparse nature of OpenStreetMap data, i.e. vertices far outnumber edges.

Compared to `jl`, this version improves runtime, memory usage, has a flexible heuristic 
function, and accounts for OpenStreetMap turn restrictions through the `cost_adjustment` function.

**Note**: A heuristic that does not accurately estimate the remaining cost to `goal` (i.e. overestimating
heuristic) will result in a non-optimal path (i.e. not the shortest), dijkstra on the other hand 
guarantees the optimal path as the heuristic cost is zero.

# Arguments
- `g::AbstractGraph{U}`: Graphs abstract graph object.
- `weights::AbstractMatrix{T}`: Edge weights matrix.
- `src::W`: Source vertex.
- `goal::W`: Goal vertex.
- `heuristic::Function=h(u, v) =  0.0`: Heuristic cost function, takes a source and target vertex, default is 0.
- `cost_adjustment:::Function=r(u, v, parents) = 0.0`: Optional cost adjustment function for use cases such as turn restrictions, takes a source and target vertex, defaults to 0.

# Return
- `Union{Nothing,Vector{U}}`: Array veritces represeting shortest path between `src` to `goal`.
"""
function astar(g::AbstractGraph{U},
               weights::AbstractMatrix{T},
               src::W,
               goal::W;
               heuristic::Function=(u, v) ->  0.0,
               cost_adjustment::Function=(u, v, parents) -> 0.0
               ) where {T <: Real, U <: Integer, W <: Integer}
    # Preallocate
    heap = BinaryHeap{Tuple{T, U, U}}(FastMin) # (f = g + h, current, path length)
    dists = fill(typemax(T), nv(g))
    parents = zeros(U, nv(g))
    visited = zeros(Bool, nv(g))
    len = zero(U)

    # Initialize src
    dists[src] = zero(T)
    push!(heap, (zero(T), src, len))

    while !isempty(heap)
        _, u, len = pop!(heap) # (f = g + h, current, path length)
        visited[u] && continue
        visited[u] = true
        len += one(U)
        u == goal && break # optimal path to goal found
        d = dists[u]

        for v in outneighbors(g, u)
            visited[v] && continue
            alt = d + weights[u, v] + cost_adjustment(u, v, parents) # turn restriction would imply `Inf` cost adjustment
            
            if alt < dists[v]
                dists[v] = alt
                parents[v] = u
                push!(heap, (alt + heuristic(v, goal), v, len))
            end
        end
    end

    return path_from_parents(parents, goal, len)
end

"""
    dijkstra(g::AbstractGraph{U},
             weights::AbstractMatrix{T},
             src::W,
             goal::W;
             cost_adjustment::Function=(u, v, parents) -> 0.0
             ) where {T <: Real, U <: Integer}

Dijkstra's shortest path algorithm with an early exit condition, is the same as astar with heuristic cost as 0.

# Arguments
- `g::AbstractGraph{U}`: Graphs abstract graph object.
- `weights::AbstractMatrix{T}`: Edge weights matrix.
- `src::W`: Source vertex.
- `goal::W`: Goal vertex.
- `cost_adjustment:::Function=r(u, v, parents) = 0.0`: Optional cost adjustment function for use cases such as turn restrictions, takes a source and target vertex, defaults to 0.

# Return
- `Union{Nothing,Vector{U}}`: Array veritces represeting shortest path between `src` to `goal`.
"""
function dijkstra(g::AbstractGraph{U},
                  weights::AbstractMatrix{T},
                  src::W,
                  goal::W;
                  cost_adjustment::Function=(u, v, parents) -> 0.0
                  ) where {T <: Real, U <: Integer, W <: Integer}
    return astar(g, weights, src, goal; cost_adjustment=cost_adjustment)
end

"""
    dijkstra(g::AbstractGraph{U},
             weights::AbstractMatrix{T},
             src::W;
             cost_adjustment::Function=(u, v, parents) -> 0.0
             ) where {T <: Real, U <: Integer, W <: Integer}

Dijkstra's shortest path algorithm, implemented with a min heap. Using a min heap is faster than using 
a priority queue given the sparse nature of OpenStreetMap data, i.e. vertices far outnumber edges.

This dispatch returns full set of `parents` or the `dijkstra state` given a source vertex, i.e. without
and early exit condition of `goal`.

# Arguments
- `g::AbstractGraph{U}`: Graphs abstract graph object.
- `weights::AbstractMatrix{T}`: Edge weights matrix.
- `src::W`: Source vertex.
- `cost_adjustment:::Function=r(u, v, parents) = 0.0`: Optional cost adjustment function for use cases such as turn restrictions, takes a source and target vertex, defaults to 0.

# Return
- `Vector{U}`: Array parent veritces from which the shortest path can be extracted.
"""
function dijkstra(g::AbstractGraph{U},
                  weights::AbstractMatrix{T},
                  src::W;
                  cost_adjustment::Function=(u, v, parents) -> 0.0
                  ) where {T <: Real, U <: Integer, W <: Integer}
    # Preallocate
    heap = BinaryHeap{Tuple{T, U}}(FastMin) # (weight, current)
    dists = fill(typemax(T), nv(g))
    parents = zeros(U, nv(g))
    visited = zeros(Bool, nv(g))

    # Initialize src
    push!(heap, (zero(T), src))
    dists[src] = zero(T)

    while !isempty(heap)
        _, u = pop!(heap) # (weight, current)
        visited[u] && continue
        visited[u] = true
        d = dists[u]

        for v in outneighbors(g, u)
            visited[v] && continue
            alt = d + weights[u, v] + cost_adjustment(u, v, parents) # turn restriction would imply `Inf` cost adjustment
            
            if alt < dists[v]
                dists[v] = alt
                parents[v] = u
                push!(heap, (alt, v))
            end
        end
    end

    return parents
end

"""
    path_from_parents(parents::Vector{<:U}, goal::V)::Vector{U} where {U <: Integer, V <: Integer}

Extracts shortest path given dijkstra parents of a given source.

# Arguments
- `parents::Vector{U}`: Array of dijkstra parent states.
- `goal::V`: Goal vertex.

# Return
- `Union{Nothing,Vector{U}}`: Array veritces represeting shortest path to `goal`.
"""
function path_from_parents(parents::Vector{<:U}, goal::V) where {U <: Integer, V <: Integer}
    parents[goal] == 0 && return
    
    pointer = goal
    path = U[]
    
    while pointer != 0 # parent of origin is always 0
        push!(path, pointer)
        pointer = parents[pointer]
    end

    return reverse(path)
end

"""
    path_from_parents(parents::Vector{<:U}, goal::V, path_length::N)::Vector{U} where {U <: Integer, V <: Integer, N <: Integer}

Extracts shortest path given dijkstra parents of a given source, providing `path_length` allows
preallocation of the array and avoids the need to reverse the path.

# Arguments
- `parents::Vector{U}`: Array of dijkstra parent states.
- `goal::V`: Goal vertex.
- `path_kength::N`: Known length of the return path, allows preallocation of final path array.

# Return
- `Union{Nothing,Vector{U}}`: Array veritces represeting shortest path to `goal`.
"""
function path_from_parents(parents::Vector{<:U}, goal::V, path_length::N) where {U <: Integer, V <: Integer, N <: Integer}
    parents[goal] == 0 && return
    
    pointer = goal
    path = Vector{U}(undef, path_length)

    for i in one(U):path_length
        path[path_length - i + one(U)] = pointer
        pointer = parents[pointer]
    end

    return path
end