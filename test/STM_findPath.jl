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
    start_node::Int64,start_element::Int64)
    #start element is using the actual index of the elements that are connected to the start node.
    println("start node: ", start_node)
    println("Start element: ", start_element)
    #containers for the path
    passed_nodes = []
    passed_elements = []

    current_node = start_node

    # println("Connected elements at start node", node_element_index[current_node])
    # first_set_of_areas = node_element_area[current_node]
    # println("first set of areas: ", first_set_of_areas)
    # min_area = maximum(first_set_of_areas)
    # elem_idx = 1 #dummy
    # for i in eachindex(first_set_of_areas)
    #     if (first_set_of_areas[i] <= min_area) && (first_set_of_areas[i] > 0)
    #         min_area = first_set_of_areas[i]
    #         elem_idx = node_element_index[current_node][i]
    #         println("found min area!")
    #     end
    # end
    current_element = start_element
    # @assert elem_idx ∈ node_element_index[current_node]

    #Pilot gave me this line, so might have to recheck in the future.
    min_area = node_element_area[current_node][node_element_index[current_node].==current_element][1]

    # keep doing until the element is repeated.
    while current_element ∉ passed_elements
        push!(passed_nodes, current_node)
        push!(passed_elements, current_element)

        # Dummy next node, not the actual next node.
        next_node = elements[current_element][1]
        if next_node == current_node
            #just in case the order of the node is repeated, switch into another side of the element.
            next_node = elements[current_element][2]
        end

        #next possible elements
        possible_elements_raw = node_element_index[next_node]

        #dont repeat the same element
        # this part is wrong. 
        # using SET
        new_elements = setdiff(possible_elements_raw, passed_elements)
        print(new_elements)
        filter = Bool[possible_elements_raw[i] ∈ new_elements for i in eachindex(possible_elements_raw)]
        
        if sum(filter) ==0
            println("no more elements to go")
            break
        end

        new_areas = node_element_area[next_node][filter]

        diff_areas = abs.(new_areas .- min_area)
        min_area = maximum(diff_areas)

        current_element = new_elements[argmax(diff_areas)]
        # elem_idx = 1 #dummy
        for i in eachindex(diff_areas)
            if (diff_areas[i] <= min_area) && (diff_areas[i] > 0)
                min_area = diff_areas[i]
                current_element= new_elements[i]
            end
        end
    current_node = next_node
    # current_element = elem_idx
    end

    push!(passed_nodes, current_node)
    push!(passed_elements, current_element)
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