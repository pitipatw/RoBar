#using StaticArrays
#structure of node
# struct Node
#     element::Vector{Int64} [ list of element that connect to the node]
# then we pass Node and can call everything. ;) 
#     y::Float64
#     z::Float64
# end
# There is going to be a bug on indexing 0 or 1 from Python to Julia
# 0 is going to be 1 and 1 is going to be 2
# This is because Julia is 1-indexed and Python is 0-indexed
# This is going to be a problem when we are trying to access the first element of a vector
# We will have to add 1 to the index to get the correct value
include("STM_capacities.jl")
include("STM_factors.jl")


"""
output node_element_unsum_score 
Dictionary of node# -> list of element# that connects to the node
"""
function nodeElementInfo(Area::Vector{Float64}, σ::Vector{Float64}, elements::Dict{Int64, Tuple{Int64, Int64}})
#program starts here
    node_element_index = Dict{Int64,Vector{Float64}}()
    node_element_unsum_score = Dict{Int64,Vector{Float64}}()
    node_element_area = Dict{Int64,Vector{Float64}}()
    list_of_forces_on_nodes = Dict{Int64,Vector{Float64}}()
    Amin = 0.001
    #could cut the time by 2 by input both ends
    for (k, v) in elements
        #if Area[k] > Amin 
            if σ[k] > 0 #might have to add tolerance here
                # tension
                val = 1.
            elseif σ[k] <= 0 # also a tolerance here
                # Compression
                val = 0.
            end

            node_element_index = assignValNode(node_element_index,v,1,k)
            node_element_index = assignValNode(node_element_index,v,2,k)
            
            #con is for condition
            node_element_unsum_score = assignValNode(node_element_unsum_score,v,1,val)
            node_element_unsum_score = assignValNode(node_element_unsum_score,v,2,val)

            node_element_area = assignValNode(node_element_area,v,1,Area[k])
            node_element_area = assignValNode(node_element_area,v,2,Area[k])

            list_of_forces_on_nodes = assignValNode(list_of_forces_on_nodes,v,1,σ[k]*Area[k])
            list_of_forces_on_nodes = assignValNode(list_of_forces_on_nodes,v,2,σ[k]*Area[k])
        
        #end
    end
    return node_element_index, node_element_unsum_score ,node_element_area, list_of_forces_on_nodes
end

function assignValNode(node_element_unsum_score::Dict{Int64,Vector{Float64}} , v ::Tuple{Int64,Int64} , i::Int64 ,val::Union{Float64,Int64})
    if haskey(node_element_unsum_score, v[i])
        push!(node_element_unsum_score[v[i]],val)
    else
        node_element_unsum_score[v[i]] = [val]
    end
    return node_element_unsum_score
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
function getScore(node_element_unsum_score::Dict{Int64,Vector{Float64}})
    list_of_keys = collect(keys(node_element_unsum_score))
    score = Dict(zip(list_of_keys, zeros(length(list_of_keys)) )) #create a dictionary of zeros
    for (k,v) in node_element_unsum_score
        score[k] = clamp( sum(v), 0, 2)
    end
    println("DONE")
    println(score)
   return score 
end
 
    #create a function to check 23.5.1 a b and 23.4.4 or beam column, 
    # otherwise, StrutCrit = 1



"""
this one tell what are the beta for each element (2 values) 
"""
function getElementsBetan(elements::Dict{Int64, Tuple{Int64, Int64}}, dict_of_betan::Dict{Int64,Float64})
    element_betan = Dict{Int64,Vector{Float64}}()
    for (k,v) in elements
        element_betan[k] = [dict_of_betan[v[1]],dict_of_betan[v[2]]]
    end
    return element_betan
end

"""
"""
function checkStrutAndTie(list_of_areas::Vector{Float64}, element_forces::Vector{Float64}, fc′::Float64)
    #list containing capacity status of each element
    element_capacity_status = Vector{Int64}(undef, length(element_forces))
    #loop each element
    for i in 1:length(element_forces)
        f = element_forces[i]
        area = list_of_areas[i]
        #check if f is tension or compression
        if f > 0 # This is tension
            #it's steel, therefore E = 200GPa
            E = 200000. #MPa
            #get strain for ϕ
            ϵ = f / (E * area)
            ϕ = getPhi(ϵ)
            #check if the force is greater than the tie capacity
            if abs(f) > ϕ*tieCapacity(420. , area) #should not say capacity, but will do for now
                element_capacity_status[i] = 0
                #print error
                println("Tie capacity exceeded")
                println("Element index: ", i)
            else
                element_capacity_status[i] = 1
            end
        else #compression
            #have to write functions or a way to find these 3 values
            StrutLoc = 0
            StrutType = 0
            StrutCrit = 0
            betaS = getBetaS(StrutLoc, StrutType,StrutCrit)
            betaC = getBetaC(1.,1.)
            ϕ = 0.65
            #check if the force is greater than the strut capacity
            if abs(f) > ϕ * strutCapacity(betaC, betaS, fc′, area)
                element_capacity_status[i] = 0
                #print error
                println("Strut capacity exceeded")
                #print index of the element
                println("Element index: ", i)
            else
                element_capacity_status[i] = 1
            end

        end
    end
    return element_capacity_status
end

"""
Bug, incompatible variable names
"""
function checkNodes(node_forces::Dict{Int64,Vector{Float64}}, node_element_index::Dict{Int64,Vector{Float64}}, list_of_areas::Vector{Float64}, fc′::Float64)
    #list containing capacity status of each node
    #it will be 1 if all of the forces that act on the node is less than the node's capacity
    node_capacity_status = Dict()#Dict{Int64, Dict{Int64,Vector{Int64}}}
    #loop each node
    for i in eachindex(node_element_index) # get node index
        # 1 pass, 0 fail
        # list of the connected elements on the node i
        connected_elements = node_element_index[i]
        node_status = Dict()

        list_of_forces = node_forces[i]

        println(connected_elements)
        println(list_of_areas)
        list_of_areas_at_the_node = list_of_areas[Int.(connected_elements)]
        # A node has many forces act on it, so we need to check each force
        #loop each force that act on the node
        for j in eachindex(list_of_forces)
            f = list_of_forces[j]
            elem_num = connected_elements[j]
            area = list_of_areas_at_the_node[j] 
            # only check compression capacity ,tension is on steel
            if f < 0 
                #get the beta for the element
                StrutLoc  = #getStrutLoc(connected_elements[j])
                StrutType = #getStrutType(connected_elements[j])
                StrutLoc = 1  
                StrutType = 1
                StrutCrit = 1
                betaS = getBetaS(StrutLoc, StrutType, StrutCrit)
                betaC = getBetaC(1.,1.)

                #check if the force is greater than the node capacity
                println("force= ", f)
                if abs(f) > nodeCapacity(betaC, betaS, fc′, area)
                    node_status[elem_num] = 0
                    #print error
                    println("Node capacity exceeded")
                    #print index of the element
                    println("At node Element index: ", j)
                else
                    println(node_status)
                    node_status[elem_num] = 1
                end
            else
                node_status[elem_num] = 1
            end
        end

        println(node_capacity_status)
        println(node_status)
        node_capacity_status[i] = node_status
    end
    return node_capacity_status
end
