module LightOSM

using Parameters
using DataStructures: DefaultDict, OrderedDict, MutableLinkedList, PriorityQueue, dequeue!, dequeue_pair!
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
       distance,
       heading,
       calculate_location,
       download_osm_network,
       graph_from_object,
       graph_from_download,
       graph_from_file,
       shortest_path,
       weights_from_path,
       total_path_weight,
       nearest_node,
       download_osm_buildings,
       buildings_from_object,
       buildings_from_download,
       buildings_from_file

include("types.jl")
include("constants.jl")
include("utilities.jl")
include("geometry.jl")
include("download.jl")
include("parse.jl")
include("graph.jl")
include("traversal.jl")
include("shortest_path.jl")
include("nearest_node.jl")
include("buildings.jl")

end # module
