str = """<nodeid="2187874238"lat="-37.8148797"lon="144.9662658"/>"""
str2 = """<node id="2180785611"lat="-37.8148306"lon="144.9689365">
<tag k="highway" v="traffic_signals"/>
</node>"""

using CombinedParsers
import CombinedParsers: word

@with_names begin
    space = Repeat( CharIn(" \r\n") )
    equals = space * "=" * space
    lat = map("lat" * equals * "\"" * Numeric(Float64) * "\"") do (_, _, _, val, _)
        (;lat = val)
    end
    lon = map("lon" * equals * "\"" * Numeric(Float64) * "\"" ) do (_, _, _, val, _)
        (;lon = val)
    end
    id = map("id" * equals * "\"" * Numeric(Int) * "\"" ) do (_, _, _, val, _)
        (;id = val)
    end
    @syntax key = (space * "k" * equals * "\"" * word * "\"" * space)[1][5]
    value = (space * "v" * equals * "\"" * word * "\""  * space)[1][5]
    @syntax tag = map("<" * space * "tag" * key * value * "/>") do a
        Pair(a[1][4], a[1][5])
    end
    @syntax tags = (space * Repeat(tag) * space)[2]

    attribute = Either{Any}([lat, lon, id])
    @syntax attributes = (space * Repeat(3,3, attribute) * space)[2]

    @syntax node_no_tags = map("<node" * attributes * "/>") do (_, atts, _)
        ntp = merge(atts...)
        ntp
        Node(ntp.id, GeoLocation(ntp.lat, ntp.lon), nothing)
    end
    @syntax node_with_tags = map("<node" * attributes * ">" * tags * "</node>") do (_, atts, _, tgs, _)
        ntp = merge(atts...)
        dict = Dict{String, Any}(tgs...)
        Node(ntp.id, GeoLocation(ntp.lat, ntp.lon), dict)
    end
end;