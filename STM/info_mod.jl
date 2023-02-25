using StaticArrays
"""
output node_element_info 
Dictionary of node# -> list of element# that connects to the node
"""
function nodeElementInfo(Area::Vector{Float64}, σ::Vector{Float64}, elements::Dict{Int64, Tuple{Int64, Int64}})
#program starts here
    node_element_info = Dict{Int64,Vector{Int64}}()
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

            node_element_info = assignValNode(node_element_info,v,1,val)
            node_element_info = assignValNode(node_element_info,v,2,val)
        end
    end
    println(node_element_info)
    return node_element_info
end

function assignValNode(node_element_info::Dict{Int64,Vector{Int64}} , v ::Tuple{Int64,Int64} , i::Int64 ,val::Int64)
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

"""
get \beta_n
input node score and output beta for capacity calculation
"""
function getBetaN(score::Dict{Int64,Float64})
    dict_of_betan = Dict{Int64,Float64}()
    for (k,v) in score
        if v == 0.
            dict_of_betan[k] = 1.0
        elseif v == 1.
            dict_of_betan[k] = 0.8
        elseif v == 2.
            dict_of_betan[k] = 0.6
        end
    end
    return dict_of_betan
end

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
Forces on nodes
"""
function getForceOnNodes(σ::Vector{Float64}, list_of_areas::Vector{Float64}, elements::Dict{Int64, Tuple{Int64, Int64}}, element_betan::Dict{Int64,Vector{Float64}})
    node_capacity= Dict{Int64,Vector{Float64}}()
    forces = σ * list_of_areas
    for (k,v) in elements
        if σ[k] >= 0
            #tension
            node_forces = assignValNode(node_forces,v,1,σ[k]*element_betan[k][1])
            node_forces = assignValNode(node_forces,v,2,σ[k]*element_betan[k][2])
        elseif σ[k] < 0
            #compression
            node_forces = assignValNode(node_forces,v,1,σ[k]*element_betan[k][1])
            node_forces = assignValNode(node_forces,v,2,σ[k]*element_betan[k][2])
        end
    end
    return node_forces
end

"""
calculate strut capacity
"""
function strutCapacity(betaC::Float64, betaS::Float64,fc′::Float64, Acs::Float64)
    fce = 0.85*betaC*betaS*fc′  # Concrete stress limit
    return fce * Acs
end

"""
"""
function tieCapacity(fy::Float64, Ats::Float64)
    return fy * Ats
end

"""
"""
function nodeCapacity(betaC::Float64, betaS::Float64,fc′::Float64, Anz::Float64)
    fce = 0.85*betaC*betaS*fc′  # Concrete stress limit
    return fce * Anz
end

"""
"""
function checkStrutAndTie(elements::Dict{Int64, Tuple{Int64, Int64}}, node_forces::Dict{Int64,Vector{Float64}}, strut_capacity::Dict{Int64,Float64}, tie_capacity::Dict{Int64,Float64})
#loop each element
    for i in 1:length(elements)
        f = element_forces[i]
        area = list_of_areas[i]
        #check if f is tension or compression
        if f > 0 # This is tension
            #check if the force is greater than the tie capacity
            if abs(f) > tie_capacity(420. , area)
                #print error
                println("Tie capacity exceeded")
                println("Element index: ", i)
            end
        else #compression
            betaS = getBetaS(StrutLoc, StrutType)
            betaC = getBetaC(betaC, betaS,fc′, Acs)
            #check if the force is greater than the strut capacity
            if abs(f) > strut_capacity(1.0, 1.0, 30.0, area)
                #print error
                println("Strut capacity exceeded")
                #print index of the element
                println("Element index: ", i)
            end

        end
    end
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