using Documenter
using LightOSM

makedocs(
    sitename="LightOSM.jl Documentation",
    # format=Documenter.HTML(prettyurls=false),
    pages=[
        "Home" => "index.md",
        "Interface" => [
            "types.md",
            "download_network.md",
            "create_graph.md",
            "shortest_path.md",
            "nearest_node.md",
            "nearest_way.md",
            "download_buildings.md",
            "create_buildings.md",
            "geolocation.md",
            "defaults.md"
        ],
        "Unit Test Use" => "testing_use.md",
    ]
)

deploydocs(
    repo="github.com/DeloitteOptimalReality/LightOSM.jl.git",
    devurl="docs",
    push_preview=true,
)