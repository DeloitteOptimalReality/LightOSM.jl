"""
    astar(g::AbstractGraph{U},
          src::W;
          goal::Union{W,Nothing}=nothing,
          distmx::AbstractMatrix{T}=weights(g),
          restrictions::Union{AbstractDict{V,Vector{MutableLinkedList{V}}},Nothing}=nothing,
          heuristic::Function=h(u, v) =  0.0,
          )::Vector{U} where {T <: Real,U <: Integer,V <: Integer,W <: Integer}

A* shortest path algorithm taken and adapted from `Graphs.jl`. This version improves runtime 
speed, memory usage, has a more flexible heruistic function, and accounts for OpenStreetMap 
turn restrictions.

# Arguments
- `g::AbstractGraph{U}`: Graphs abstract graph object.
- `src::W`: Source vertex.
- `goal::Union{W,Nothing}=nothing`: Optional target vertex as a break condition.
- `distmx::AbstractMatrix{T}=weights(g)`: Optional weight matrix.
- `restrictions::Union{AbstractDict{V,Vector{MutableLinkedList{V}}},Nothing}=nothing`: Optional 
dictionary of restrictions, keyed by vertex, each restriction is a linked list of vertices, 
any path containing the entire list will have an infinite cost assigned to it.
- `heuristic::Function=h(u, v) =  0.0`: Heuristic cost function, takes a source and target vertex, default is 0.

# Return
- `Vector{U}`: Array parent veritces from which the shortest path can be extracted.
"""
function astar(g::AbstractGraph{U},
               src::W;
               goal::Union{W,Nothing}=nothing,
               distmx::AbstractMatrix{T}=weights(g),
               restrictions::Union{AbstractDict{V,Vector{MutableLinkedList{V}}},Nothing}=nothing,
               heuristic::Function=h(u, v) =  0.0,
               )::Vector{U} where {T <: Real,U <: Integer,V <: Integer,W <: Integer}
    nvg = nv(g)
    
    # Preallocate
    visited = zeros(Bool, nvg)
    H = PriorityQueue{U,T}()
    dists = fill(typemax(T), nvg)
    parents = zeros(U, nvg)

    # Initialize src
    H[src] = zero(T)
    dists[src] = zero(T)
    parents[src] = 0

    while !isempty(H)
        u = dequeue!(H)
        d = dists[u]
        visited[u] = true

        for v in outneighbors(g, u)
            visited[v] && continue

            dist_u_v = distmx[u, v]

            if restrictions !== nothing && haskey(restrictions, u)
                for ll in restrictions[u]
                    if is_restricted(ll, u, v, parents)
                        dist_u_v = typemax(T) # Means path from u -> v is restricted, given parents
                        break
                    end
                end
            end

            alt = d + dist_u_v

            if alt < dists[v]
                H[v] = alt + heuristic(v, goal)
                dists[v] = alt
                parents[v] = u
                if goal == v && goal == peek(H).first
                    # If v is the goal (destination) and the goal is the first node in the
                    # priotity queue, we have found the optimal path so return parents
                    return parents
                end
            end
        end
    end

    return parents
end

"""
Dijkstra shortest path algorithm, same as A* but without a heuristic cost function.
"""
function dijkstra(g::AbstractGraph{U},
                  src::W;
                  goal::Union{W,Nothing}=nothing,
                  distmx::AbstractMatrix{T}=weights(g),
                  restrictions::Union{AbstractDict{V,Vector{MutableLinkedList{V}}},Nothing}=nothing
                  )::Vector{U} where {T <: Real,U <: Integer,V <: Integer,W <: Integer}
    return astar(g, src, goal=goal, distmx=distmx, restrictions=restrictions)
end

"""
    is_restricted(restriction_ll::MutableLinkedList{V}, u::U, v::U, parents::Vector{U})::Bool where {U <: Integer,V <: Integer}

Returns true if path between u and v is restricted, given parents.

# Arguments
- `restriction_ll::MutableLinkedList{V}`: Linked list holding vertices in order of v -> parents.
- `u::U`: Current vertex visiting.
- `v::U`: Current neighbour vertex.
- `parents::Vector{U}`: Vector mapping of shortest path parents.

# Return
- `Bool`: Returns true if path between u and v is restricted.
"""
function is_restricted(restriction_ll::MutableLinkedList{V}, u::U, v::U, parents::Vector{U})::Bool where {U <: Integer,V <: Integer}
    current = restriction_ll.node.next

    if v != current.data
        return false
    end

    checked = 1 # already checked v

    while checked < restriction_ll.len
        current = current.next

        if u == current.data
            u = parents[u]
        else
            return false
        end

        checked += 1
    end

    return true
end
