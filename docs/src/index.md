# LightOSM.jl

`LightOSM.jl` is **[Julia](https://julialang.org/)** package for downloading and analysing geospatial data from **[OpenStreetMap](https://wiki.openstreetmap.org/wiki/Main_Page)** APIs (**[Nominatim](https://nominatim.openstreetmap.org/ui/search.html)** and **[Overpass](https://overpass-api.de)**), such as nodes, ways, relations and building polygons.

## Interface

```@contents
Pages = [
    "types.md",
    "download_network.md",
    "create_graph.md",
    "shortest_path.md",
    "nearest_node.md",
    "download_buildings.md",
    "create_buildings.md",
    "geolocation.md"
]
```

## Acknowledgements

`LightOSM.jl` is inspired by the Python package **[OSMnx](https://github.com/gboeing/osmnx)** for its interface and Overpass query logic. Graph analysis algorithms (connected components and shortest path) are based on **[LightGraphs.jl](https://github.com/JuliaGraphs/LightGraphs.jl)** implementation, but adapted to account for turn restrictions and improve runtime performance.

Another honourable mention goes to an existing Julia package **[OpenStreetMapX.jl](https://github.com/pszufe/OpenStreetMapX.jl)** as many learnings were taken to improve parsing of raw OpenStreetMap data.

## Key Features

- `Search`, `download` and `save` OpenSteetMap data in .osm, .xml or .json, using a place name, centroid point or bounding box
- Parse OpenStreetMap `transport network` data such as motorway, cycleway or walkway
- Parse OpenStreetMap `buildings` data into a format consistent with the **[GeoJSON](https://tools.ietf.org/html/rfc7946)** standard, allowing for visualisation with libraries such as **[deck.gl](https://github.com/visgl/deck.gl)**
- Calculate `shortest path` between two nodes using the Dijkstra or A\* algorithm (based on LightGraphs.jl, but adapted for better performance and use cases such as `turn resrictions`)
- Find `nearest nodes` from a query point using a K-D Tree data structure (implemented using **[NearestNeighbors.jl](https://github.com/KristofferC/NearestNeighbors.jl)**)

## Usage

A comprehensive tutorial can be found found **[here](https://deloittedigitalapac.github.io/LightOSM.jl/notebooks/tutorial)**.

## Benchmarks

Benchmark comparison for shortest path algorithms can be found **[here](https://deloittedigitalapac.github.io/LightOSM.jl/notebooks/benchmarks)**.
