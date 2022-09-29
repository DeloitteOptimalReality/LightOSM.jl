"""
    astar([::Type{<:AStar},]
          g::AbstractGraph{U},
          weights::AbstractMatrix{T},
          src::W,
          goal::W;
          heuristic::Function=(u, v) ->  0.0,
          cost_adjustment::Function=(u, v, parents) -> 0.0,
          max_distance::T=typemax(T)
          ) where {T <: Real, U <: Integer, W <: Integer}

A* shortest path algorithm. Implemented with a min heap. Using a min heap is 
faster than using a priority queue given the sparse nature of OpenStreetMap 
data, i.e. vertices far outnumber edges.

There are two implementations:
- `AStarVector` is faster for small graphs and/or long paths. This is default. 
    It pre-allocates vectors at the start of the algorithm to store 
    distances, parents and visited nodes. This speeds up graph traversal at the 
    cost of large memory usage.
- `AStarDict` is faster for large graphs and/or short paths.
    It dynamically allocates memory during traversal to store distances, 
    parents and visited nodes. This is faster compared to `AStarVector` when 
    the graph contains a large number of nodes and/or not much traversal is 
    required.

Compared to `jl`, this version improves runtime, memory usage, has a flexible 
heuristic function, and accounts for OpenStreetMap turn restrictions through 
the `cost_adjustment` function.

**Note**: A heuristic that does not accurately estimate the remaining cost to 
`goal` (i.e. overestimating heuristic) will result in a non-optimal path 
(i.e. not the shortest), dijkstra on the other hand guarantees the optimal path 
as the heuristic cost is zero.

# Arguments
- `::Type{<:AStar}`: Implementation to use, either `AStarVector` (default) or 
    `AStarDict`.
- `g::AbstractGraph{U}`: Graphs abstract graph object.
- `weights::AbstractMatrix{T}`: Edge weights matrix.
- `src::W`: Source vertex.
- `goal::W`: Goal vertex.
- `heuristic::Function=h(u, v) =  0.0`: Heuristic cost function, takes a source 
    and target vertex, default is 0.
- `cost_adjustment:::Function=r(u, v, parents) = 0.0`: Optional cost adjustment 
    function for use cases such as turn restrictions, takes a source and target 
    vertex, defaults to 0.
- `max_distance::T=typemax(T)`: Maximum weight to traverse the graph, returns 
    `nothing` if this is reached.

# Return
- `Union{Nothing,Vector{U}}`: Array veritces represeting shortest path from 
    `src` to `goal`.
"""
function astar(::Type{A},
               g::AbstractGraph{U},
               weights::AbstractMatrix{T},
               src::W,
               goal::W;
               heuristic::Function=(u, v) ->  0.0,
               cost_adjustment::Function=(u, v, parents) -> 0.0,
               max_distance::T=typemax(T)
               ) where {A <: AStar, T <: Real, U <: Integer, W <: Integer}
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
        d > max_distance && return # reached max distance

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
function astar(::Type{AStarDict},
               g::AbstractGraph{U},
               weights::AbstractMatrix{T},
               src::W,
               goal::W;
               heuristic::Function=(u, v) ->  0.0,
               cost_adjustment::Function=(u, v, parents) -> 0.0,
               max_distance::T=typemax(T)
               ) where {T <: Real, U <: Integer, W <: Integer}
    # Preallocate
    heap = BinaryHeap{Tuple{T, U, U}}(FastMin) # (f = g + h, current, path length)
    dists = Dict{U, T}()
    parents = Dict{U, U}()
    visited = Set{U}()
    len = zero(U)

    # Initialize src
    dists[src] = zero(T)
    push!(heap, (zero(T), src, len))

    while !isempty(heap)
        _, u, len = pop!(heap) # (f = g + h, current, path length)
        u in visited && continue
        push!(visited, u)
        len += one(U)
        u == goal && break # optimal path to goal found
        d = get(dists, u, typemax(T))
        d > max_distance && return # reached max distance

        for v in outneighbors(g, u)
            v in visited && continue
            alt = d + weights[u, v] + cost_adjustment(u, v, parents) # turn restriction would imply `Inf` cost adjustment
            
            if alt < get(dists, v, typemax(T))
            dists[v] = alt
                parents[v] = u
                push!(heap, (alt + heuristic(v, goal), v, len))
            end
        end
    end

    return path_from_parents(parents, goal, len)
end
function astar(g::AbstractGraph{U},
               weights::AbstractMatrix{T},
               src::W,
               goal::W;
               kwargs...
               ) where {T <: Real, U <: Integer, W <: Integer}
    return astar(AStarVector, g, weights, src, goal; kwargs...)
end

"""
dijkstra([::Type{<:Dijkstra},]
         g::AbstractGraph{U},
         weights::AbstractMatrix{T},
         src::W,
         goal::W;
         cost_adjustment::Function=(u, v, parents) -> 0.0,
         max_distance::T=typemax(T)
         ) where {T <: Real, U <: Integer, W <: Integer}

Dijkstra's shortest path algorithm with an early exit condition, is the same as 
astar with heuristic cost as 0.

There are two implementations:
- `DijkstraVector` is faster for small graphs and/or long paths. This is default. 
    It pre-allocates vectors at the start of the algorithm to store 
    distances, parents and visited nodes. This speeds up graph traversal at the 
    cost of large memory usage.
- `DijkstraDict` is faster for large graphs and/or short paths.
    It dynamically allocates memory during traversal to store distances, 
    parents and visited nodes. This is faster compared to `AStarVector` when 
    the graph contains a large number of nodes and/or not much traversal is 
    required.

# Arguments
- `::Type{<:Dijkstra}`: Implementation to use, either `DijkstraVector` 
    (default) or `DijkstraDict`.
- `g::AbstractGraph{U}`: Graphs abstract graph object.
- `weights::AbstractMatrix{T}`: Edge weights matrix.
- `src::W`: Source vertex.
- `goal::W`: Goal vertex.
- `cost_adjustment:::Function=r(u, v, parents) = 0.0`: Optional cost adjustment 
    function for use cases such as turn restrictions, takes a source and target 
    vertex, defaults to 0.
- `max_distance::T=typemax(T)`: Maximum weight to traverse the graph, returns 
    `nothing` if this is reached.

# Return
- `Union{Nothing,Vector{U}}`: Array veritces represeting shortest path between `src` to `goal`.
"""
function dijkstra(::Type{A},
                  g::AbstractGraph{U},
                  weights::AbstractMatrix{T},
                  src::W,
                  goal::W;
                  kwargs...
                  ) where {A <: Dijkstra, T <: Real, U <: Integer, W <: Integer}
    return astar(AStarVector, g, weights, src, goal; kwargs...)
end
function dijkstra(::Type{DijkstraDict},
                  g::AbstractGraph{U},
                  weights::AbstractMatrix{T},
                  src::W,
                  goal::W;
                  kwargs...
                  ) where {T <: Real, U <: Integer, W <: Integer}
    return astar(AStarDict, g, weights, src, goal; kwargs...)
end
function dijkstra(g::AbstractGraph{U},
                  weights::AbstractMatrix{T},
                  src::W,
                  goal::W;
                  kwargs...
                  ) where {T <: Real, U <: Integer, W <: Integer}
    return dijkstra(DijkstraVector, g, weights, src, goal; kwargs...)
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
    path_from_parents(parents::P, goal::V) where {P <: Union{<:AbstractVector{<:U}, <:AbstractDict{<:U, <:U}}} where {U <: Integer, V <: Integer}

Extracts shortest path given dijkstra parents of a given source.

# Arguments
- `parents::Union{<:AbstractVector{<:U}, <:AbstractDict{<:U, <:U}}`: Mapping of 
    dijkstra parent states.
- `goal::V`: Goal vertex.

# Return
- `Union{Nothing,Vector{U}}`: Array veritces represeting shortest path to `goal`.
"""
function path_from_parents(parents::P, goal::V) where {P <: Union{<:AbstractVector{<:U}, <:AbstractDict{<:U, <:U}}} where {U <: Integer, V <: Integer}
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
    path_from_parents(parents::P, goal::V, path_length::N) where {P <: Union{<:AbstractVector{<:U}, <:AbstractDict{<:U, <:U}}} where {U <: Integer, V <: Integer, N <: Integer}

Extracts shortest path given dijkstra parents of a given source, providing `path_length` allows
preallocation of the array and avoids the need to reverse the path.

# Arguments
- `parents::Union{<:AbstractVector{<:U}, <:AbstractDict{<:U, <:U}}`: Mapping of dijkstra parent states.
- `goal::V`: Goal vertex.
- `path_kength::N`: Known length of the return path, allows preallocation of final path array.

# Return
- `Union{Nothing,Vector{U}}`: Array veritces represeting shortest path to `goal`.
"""
function path_from_parents(parents::P, goal::V, path_length::N) where {P <: Union{<:AbstractVector{<:U}, <:AbstractDict{<:U, <:U}}} where {U <: Integer, V <: Integer, N <: Integer}
    get(parents, goal, zero(U)) == 0 && return
    
    pointer = goal
    path = Vector{U}(undef, path_length)

    for i in one(U):(path_length - 1)
        path[path_length - i + one(U)] = pointer
        pointer = parents[pointer]
    end
    path[1] = pointer

    return path
end
