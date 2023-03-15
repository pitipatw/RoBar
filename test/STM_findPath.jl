"""
calculate feasible starting node_point
which is the node with the non-zero area
"""
function feasibleStartingPoints(node_element_area::Dict{Int64,Vector{Float64}})
    feasible_points = []
    for (k,v) in node_element_area
        if sum(v.>0) > 0
            push!(feasible_points, k)
        end
    end
    return feasible_points
end



"""
longest path problem
have to process the elements area first
"""
function findPath(node_element_area::Dict{Int64,Vector{Float64}},node_element_index::Dict{Int64, Vector{Float64}}, elements::Dict{Int64, Tuple{Int64, Int64}},
    start_node::Int64,start_element_rel_idx::Int64) #this is optional
    #start element is using the actual index of the elements that are connected to the start node.
    println("start node: ", start_node)
    
    passed_nodes = []
    passed_elements = []
    current_node = start_node
    println("Connected elements at start node", node_element_index[current_node])
    first_set_of_areas = node_element_area[current_node]
    println("first set of areas: ", first_set_of_areas)
    min_area = maximum(first_set_of_areas)
    elem_ind = 1 #dummy
    for i in eachindex(first_set_of_areas)
        if (first_set_of_areas[i] <= min_area) && (first_set_of_areas[i] > 0)
            min_area = first_set_of_areas[i]
            elem_ind = node_element_index[current_node][i]
            println("found min area!")
        end
    end
    current_element = elem_ind
    @assert elem_ind ∈ node_element_index[current_node]

    while current_element ∉ passed_elements
        push!(passed_nodes, current_node)
        push!(passed_elements, elem_ind)

        next_node = elements[elem_ind][1]
        if next_node == current_node
            next_node = elements[elem_ind][2]
        end

        next_elements = node_element_index[next_node]
        filter = next_elements .!= current_element
        possible_elements = next_elements[filter]

        new_areas = node_element_area[next_node][filter]
        diff_areas = abs.(new_areas .- min_area)
        min_area = maximum(diff_areas)

        elem_ind = 1 #dummy
        for i in eachindex(diff_areas)
            if (diff_areas[i] <= min_area) && (diff_areas[i] > 0)
                min_area = diff_areas[i]
                elem_ind = possible_elements[i]
            end
        end
    current_node = next_node
    current_element = elem_ind
    end

    push!(passed_nodes, current_node)
    push!(passed_elements, elem_ind)
    return passed_nodes, passed_elements
end

# 
# visualization

# """
# """
# (Any[1, 4, 8, 5], Any[3.0, 17.0, 20.0, 20.0])

# julia> node_element_index
# Dict{Int64, Vector{Float64}} with 8 entries:
#   5 => [16.0, 20.0, 19.0, 9.0, 4.0, 21.0]
#   4 => [16.0, 12.0, 8.0, 17.0, 3.0, 18.0]
#   6 => [5.0, 19.0, 22.0, 23.0, 13.0, 10.0]
#   7 => [24.0, 23.0, 6.0, 15.0, 18.0, 21.0]
#   2 => [8.0, 1.0, 11.0, 9.0, 7.0, 10.0]
#   8 => [20.0, 24.0, 17.0, 22.0, 11.0, 14.0]
#   3 => [12.0, 14.0, 7.0, 13.0, 15.0, 2.0]
#   1 => [5.0, 1.0, 6.0, 3.0, 4.0, 2.0]
#   """