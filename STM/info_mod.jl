using StaticArrays
include("capacities.jl")
include("factors.jl")
"""
output node_element_info 
Dictionary of node# -> list of element# that connects to the node
"""
function nodeElementInfo(Area::Vector{Float64}, σ::Vector{Float64}, elements::Dict{Int64, Tuple{Int64, Int64}})
#program starts here
    node_element_info = Dict{Int64,Vector{Float64}}()
    list_of_forces_on_nodes = Dict{Int64,Vector{Float64}}()
    #could cut the time by 2 by input both ends
    for (k, v) in elements
        if Area[k] > Amin 
            if σ[k] >= 0 #might have to add tolerance here
                # tension
                val = 1.
            elseif σ[k] < 0 # also a tolerance here
                # Compression
                val = 0.
            end

            node_element_info = assignValNode(node_element_info,v,1,val)
            node_element_info = assignValNode(node_element_info,v,2,val)
            list_of_forces_on_nodes = assignValNode(list_of_forces_on_nodes,v,1,σ[k]*Area[k])
            list_of_forces_on_nodes = assignValNode(list_of_forces_on_nodes,v,2,σ[k]*Area[k])
        
        end
    end
    println(node_element_info)
    return node_element_info , list_of_forces_on_nodes
end

function assignValNode(node_element_info::Dict{Int64,Vector{Float64}} , v ::Tuple{Int64,Int64} , i::Int64 ,val::Float64)
    if haskey(node_element_info, v[i])
        push!(node_element_info[v[i]],val)
    else
        node_element_info[v[i]] = [val]
    end
    return node_element_info
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
function getScore(node_element_info::Dict{Int64,Vector{Int64}})
    list_of_keys = collect(keys(node_element_info))
    score = Dict(zip(list_of_keys, zeros(length(list_of_keys)) )) #create a dictionary of zeros
    for (k,v) in node_element_info
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

end

"""
"""
function checkStrutAndTie(elements::Dict{Int64, Tuple{Int64, Int64}}, node_forces::Dict{Int64,Vector{Float64}}, strut_capacity::Dict{Int64,Float64}, tie_capacity::Dict{Int64,Float64})
#list containing capacity status of each element
    element_capacity_status = Vector{Int64}(undef, length(elements))
    #loop each element
    for i in 1:length(elements)
        f = element_forces[i]
        area = list_of_areas[i]
        #check if f is tension or compression
        if f > 0 # This is tension
            #it's steel, therefore E = 200GPa
            E = 200000. #MPa
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
            betaS = getBetaS(StrutLoc, StrutType)
            betaC = getBetaC(betaC, betaS,fc′, Acs)
            ϕ = 0.65
            #check if the force is greater than the strut capacity
            if abs(f) > ϕ * strutCapacity(betaC, betaA, fc′, area) #also should not say capacity
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
"""
function checkNodes(elements::Dict{Int64, Tuple{Int64, Int64}}, node_forces::Dict{Int64,Vector{Float64}},list_of_forces_on_nodes::Dict{Int64,Vector{Float64}})
    #list containing capacity status of each node
    #it will be 1 if all of the forces that act on the node is less than the node's capacity
    node_capacity_status = Dict(Int64,Vector{Int64})()
    #check only compression, therefore ϕ = 0.65
    ϕ = 0.65
    #loop each node
    for i in 1:length(nodes)
        #loop each force that act on the node
        list_of_forces = list_of_forces_on_nodes[i]
        for f in list_of_forces 
            #this has to match with the area of each element
            if f < 0 # only check compression tension is on steel
                betaS = getBetaS(StrutLoc, StrutType)
                betaC = getBetaC(betaC, betaS,fc′, Acs)
                #check if the force is greater than the node capacity
                if abs(f) > ϕ * nodeCapacity(betaC, betaA, fc′, area) #also should not say capacity
                    assignValNode(node_element_info,v,1,0)
                    #print error
                    println("Strut capacity exceeded")
                    #print index of the element
                    println("Element index: ", i)
                else
                    element_capacity_status[i] = 1
                end


            end
    return node_capacity_status
end

"""
"""

"""
"""



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