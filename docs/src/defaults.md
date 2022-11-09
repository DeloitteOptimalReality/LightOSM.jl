# Default Values
## Ways
During parsing, only `way`s with tags and nodes are considered. Further, the tags have to contain a key of either `"highway"` or `"railway"`. If the tags contain tags which have been excluded due to the `network_type` keyword (e.g. on download) are also discarded. This is relevant, if you downloaded the full network and want to generate only the `:bike` network from it.

### Highways
The returned `Way` is guaranteed to have the following `keys`:
- (`highway::String`)
- `maxspeed::DEFAULT_OSM_MAXSPEED_TYPE` 
    - If the tag exists before parsing, `LightOSM` attempts to parse the content to a number in km/h, while automatically converting units of `mph`. If multiple speeds are mapped, the average is returned. 
    - If the tag does not exist before parsing, the default value as given by `DEFAULT_MAXSPEEDS[tags["highway"]]` is returned. If there is no tag with key `"highway"` in `DEFAULT_MAXSPEEDS`, then `DEFAULT_MAXSPEEDS["other"]` is used.
- `oneway::Bool` 
- `reverseway::Bool`
- `lanes::DEFAULT_OSM_LANES_TYPE`
    - If the tag exists before parsing, `LightOSM` attempts to parse the content to a `DEFAULT_OSM_LANES_TYPE`
    - If the tag does not exist before parsing, the default value as given by `DEFAULT_LANES[tags["highway"]]` is returned. If there is no tag with key `"highway"` in `DEFAULT_LANES`, then `DEFAULT_LANES["other"]` is used.

- `lanes:forward::DEFAULT_OSM_LANES_TYPE`
    - If the way is `oneway` and `reverseway` this value is 0
    - If the way is `oneway` and not `reverseway` this value is the same as the `lanes` tag
    - If the way is not `oneway`, the value is parsed like `lanes`, but with `"lanes"=>"lanes:forward"`

- `lanes:backward::DEFAULT_OSM_LANES_TYPE`
    - If the way is `oneway` and not `reverseway` this value is 0
    - If the way is `oneway` and `reverseway` this value is the same as the `lanes` tag
    - If the way is not `oneway`, the value is parsed like `lanes`, but with `"lanes"=>"lanes:backward"`

- `lanes:both_ways::DEFAULT_OSM_LANES_TYPE`
    - If the way is `oneway`, this value is 0
    - If the way is not `oneway`:
        - If the tag exists before parsing, `LightOSM` attempts to parse the content to a `DEFAULT_OSM_LANES_TYPE`
        - If the tag does not exist before parsing, the default value as given by `DEFAULT_LANES_BOTH_WAYS[tags["highway"]]` is returned. If there is no tag with key `"highway"` in `DEFAULT_LANES_BOTH_WAYS`, `DEFAULT_LANES_BOTH_WAYS["other"]` is used. 

all further tags present on the original way are preserved, but not parsed to appropriate datatypes, but rather left as `String`.

See [here](https://github.com/DeloitteOptimalReality/LightOSM.jl/blob/master/src/parse.jl#L4) for the full implementation of the `maxspeed` parsing, and [here](https://github.com/DeloitteOptimalReality/LightOSM.jl/blob/master/src/parse.jl#L56) for the full implementation of any `lanes` parsing.

### Railways
The returned `Way` is guaranteed to have the following `keys`:
- (`railway::String`)
- `rail_type::String` set to `"unknown"` if not mapped
- `electrified::String` set to `"unknown"` if not mapped
- `gauge::Union{String, Nothin}` set to `nothing` if not mapped
- `usage::String` set to `"unknown"` if not mapped
- `name::String` set to `"unknown"` if not mapped
- `lanes::Union{String, Int64}` set to `1` if not mapped.
- `maxspeed::DEFAULT_OSM_MAXSPEED_TYPE`
- `oneway::DEFAULT_OSM_LANES_TYPE`
- `reverseway::DEFAULT_OSM_LANES_TYPE`

all further tags present on the original `way` are preserved, but not parsed to appropriate datatypes, but rather left as `String`.

The tags `maxspeed`, `oneway` and `reverseway` are set in the same way as described in [highways](#Highways).

## Buildings
During parsing, only `relation`s and `way`s with tags, where one of these tags has to have a key of `"building"` are considered. After parsing, the following `keys` are guaranteed to exist:
- (`building`)
- `height` (see [here](https://github.com/DeloitteOptimalReality/LightOSM.jl/blob/master/src/buildings.jl#L171) for source)

The height value is parsed via the funcitno 


all further tags present in the original object are preserved, but not parsed to appropriate datatypes, but rather left as `String`.


```@docs
LightOSM.set_defaults
```
