function gen_node_prop(σ::Vector{Float64} ,node_points::Dict{Int64, SVector{3, Float64}}, elements ::Dict{Int64, Tuple{Int64, Int64}})
    node_labels = collect(keys(node_points)) 
    node_prop = Dict(Int, Vector{Int})

    for i in node_labels
        # i is an index
        # find elements number that connect to that node. 
        node2elements = Dict()
        #could cut the time by 2 by input both ends
        for (k, v) in elements
            println(k)
            if haskey(node2elements, v)
                push!(node2elements[v],k)
            else
                node2elements[v] = [k]
            end
        end

        if σi > 0 #tension
            push!(node_prop[i],1)
        elseif σi < 0 #Compression
            push!(node_prop[i],0)
        end
    end

    
end

function node_mod(nodes::Dict{Int64,Vector{Float64}})
    # Tension : 1
    # Compression : 0
    # form 0 : [ 0 1 1]
    for (k,v) in nodes
        indicator = sum(v) 
        # this could pass into another function
        if indicator == 0 
            #all Compression
            #set value of beta β
        elseif indicator == 1 
            # 1 tension (CCT or better) 
            # set value of bata β

        elseif indicator >= 2
            # this is CTT or worse 
            # set a value of beta β
        end
    node_factor[k] = β
    return nodes

end 