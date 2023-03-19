"""
find the total length of each path in pass Nodes
"""
function totalLength(possible_paths::Any, element_lengths::Any)
    path_lengths = Dict()
    for (k,v) in possible_paths
        total_length = 0
        path = v[2]
        for i in eachindex(path)
            element = path[i]
            total_length += element_lengths[Int(element)]
        end
        path_lengths[k] = total_length
    end
return path_lengths
end