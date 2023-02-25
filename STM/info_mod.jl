using StaticArrays
"""
output nodeElementInfo 
Dictionary of node# -> list of element# that connects to the node
"""
function node_element_info(Area::Vector{Float64}, σ::Vector{Float64}, elements::Dict{Int64, Tuple{Int64, Int64}})
#program starts here
    nodeElementInfo = Dict{Int64,Vector{Int64}}()
    #could cut the time by 2 by input both ends
    for (k, v) in elements
        if Area[k] > Amin 
            if σ[k] >= 0 #might have to add tolerance here
                # tension
                val = 1
            elseif σ[k] < 0 # also a tolerance here
                # Compression
                val = 0
            end

            nodeElementInfo = assignValNode(nodeElementInfo,v,1,val)
            nodeElementInfo = assignValNode(nodeElementInfo,v,2,val)
        end
    end
    println(nodeElementInfo)
return nodeElementInfo
end

function assignValNode(nodeElementInfo::Dict{Int64,Vector{Int64}} , v ::Tuple{Int64,Int64} , i::Int64 ,val::Int64)
    if haskey(nodeElementInfo, v[i])
        push!(nodeElementInfo[v[i]],val)
    else
        nodeElementInfo[v[i]] = [val]
    end
    return nodeElementInfo
end
# fuhction that get values into keys (it ran 2 times on the above funciton, could be shorter)
#create function that group the 

"""
4.4.1 pg15
Strut efficiency factor betas
"""

"""
Get Score CCC = 0 CCT = 1 CTT = 2

"""
function getScore(nodeElementInfo::Dict{Int64,Vector{Int64}})
    list_of_keys = collect(keys(nodeElementInfo))
    score = Dict(zip(list_of_keys, zeros(length(list_of_keys)) )) #create a dictionary of zeros
    for (k,v) in nodeElementInfo
        if sum(v) == 0
            score[k] = 2
        elseif sum(v) == 1
            score[k] = 1
        elseif sum(v) >= 2
            score[k] = 0
        end
    end
    println("DONE")
    println(score)
   return score 
end

"""



"""
boundary strut = 1 
0.75
worst = 0.4
"""
function getβs(StrutLoc::Int64, StrutType::Int64)
    if StrutLoc == 0 
        βs= 0.4
    else
        if StrutType ==0
            βs = 1.0
        else
            if StrutCrit != 0
                βs = 0.40
            end
        end
    end

return βs
end

    #create a function to check 23.5.1 a b and 23.4.4 or beam column, 
    # otherwise, StrutCrit = 1





function gen_node_prop(σ::Vector{Float64} ,node_points::Dict{Int64, SVector{3, Float64}}, elements ::Dict{Int64, Tuple{Int64, Int64}})
    node_labels = collect(keys(node_points)) 
    node_prop = Dict(Int, Vector{Int})
    for i in node_labels
        # i is an index
        # find elements number that connect to that node. 
        nodeElementInfo = Dict()
        #could cut the time by 2 by input both ends
        for (k, v) in elements
            println(k)
            if haskey(nodeElementInfo, v)
                push!(nodeElementInfo[v],k)
            else
                nodeElementInfo[v] = [k]
            end
        end

        if σ > 0 #tension
            push!(node_prop[i],1)
        elseif σ < 0 #Compression
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
    end 

    return nodes
end