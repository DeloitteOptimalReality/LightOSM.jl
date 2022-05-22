module LightOSM

using Parameters
using DataStructures: DefaultDict, OrderedDict, MutableLinkedList
using QuickHeaps: BinaryHeap, FastMin
using Statistics: mean
using SparseArrays: SparseMatrixCSC, sparse
using Graphs: AbstractGraph, DiGraph, nv, outneighbors, weakly_connected_components, vertices
using StaticGraphs: StaticDiGraph
using SimpleWeightedGraphs: SimpleWeightedDiGraph
using MetaGraphs: MetaDiGraph
using NearestNeighbors: KDTree, knn
using HTTP
using JSON
using LightXML

export GeoLocation,
       OSMGraph,
       Node,
       Way,
       Restriction,
       Building,
       PathAlgorithm,
       Dijkstra,
       AStar,
       distance,
       heading,
       calculate_location,
       download_osm_network,
       graph_from_object,
       graph_from_download,
       graph_from_file,
       shortest_path,
       shortest_path_from_dijkstra_state,
       set_dijkstra_state!,
       restriction_cost_adjustment,
       distance_heuristic,
       time_heuristic,
       weights_from_path,
       total_path_weight,
       path_from_parents,
       nearest_node,
       download_osm_buildings,
       buildings_from_object,
       buildings_from_download,
       buildings_from_file

export index_to_node_id,
       index_to_node,
       node_id_to_index,
       node_to_index,
       index_to_dijkstra_state,
       node_id_to_dijkstra_state,
       set_dijkstra_state_with_index!,
       set_dijkstra_state_with_node_id!,
       maxspeed_from_index,
       maxspeed_from_node_id

include("types.jl")
include("constants.jl")
include("utilities.jl")
include("geometry.jl")
include("download.jl")
include("parse.jl")
include("graph.jl")
include("graph_utilities.jl")
include("traversal.jl")
include("shortest_path.jl")
include("nearest_node.jl")
include("buildings.jl")

end # module
