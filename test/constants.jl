dict = Dict(
    "first" => ["single"],
    "second" => ["dual1", "dual2"]
)

single_dict = Dict("first" => ["single"])
single_str = LightOSM.concatenate_exclusions(single_dict)
@test startswith(single_str, '[')
@test endswith(single_str, ']')
args_only = chop(single_str, head=1, tail=1)
args = split(args_only, "!~")
@test args[1] == "\"first\""
@test args[2] == "\"single\""

dual_dict = Dict("second" => ["dual1", "dual2"])
dual_str = LightOSM.concatenate_exclusions(dual_dict)
@test startswith(dual_str, '[')
@test endswith(dual_str, ']')
args_only = chop(dual_str, head=1, tail=1)
args = split(args_only, "!~")
@test args[1] == "\"second\""
@test args[2] == "\"dual1|dual2\""

combined_dict = dict = Dict(
    "first" => ["single"],
    "second" => ["dual1", "dual2"]
)
str = LightOSM.concatenate_exclusions(combined_dict)
@test str == single_str * dual_str || str == dual_str * single_str # either order