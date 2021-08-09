wait_for_overpass()

data = download_osm_network(:point, radius=0.5,
                            point=GeoLocation(-37.8136, 144.9631),
                            network_type=:drive)

g_distance = graph_from_object(data, weight_type=:distance)
g_time = graph_from_object(data, weight_type=:time)

@test g_distance isa LightOSM.OSMGraph # Replace by better tests at somepoint, just want an initial test now
@test g_time isa LightOSM.OSMGraph # Replace by better tests at somepoint, just want an initial test now