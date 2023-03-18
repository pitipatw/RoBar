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
        I = 0
        for i in eachindex(diff_areas)
            if (diff_areas[i] <= min_area) && (diff_areas[i] > 0)
                min_area = diff_areas[i]
                current_element= new_elements[i]
                I = i
            end
        end
        # println(diff_areas)
        # @assert I == argmin(diff_areas)
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



"""
Ver2
longest path problem 
have to process the elements area first
"""
function findPath2(node_element_area_input::Dict{Int64,Vector{Float64}},node_element_index::Dict{Int64, Vector{Float64}}, elements::Dict{Int64, Tuple{Int64, Int64}},
    start_node::Int64,start_element::Int64, fixed_area ::Float64)
    node_element_area = copy(node_element_area_input)
    #start element is using the actual index of the elements that are connected to the start node.
    println("start node: ", start_node)
    println("Start element: ", start_element)
    #containers for the path
    passed_nodes = []
    passed_elements = [] #get order of the passes elemetns

    current_node = start_node
    current_element = start_element
    # n_available_elements is the number of elements that are connected to the current node that has area> 0
    n_available_elements = length(node_element_area[current_node][node_element_area[current_node].>0])
    

    # keep doing until the element is repeated.
    # while n_available_elements != 0
    counter = 0
    while true
        print(counter)
        counter += 1
        if counter >= 1000
            println("Max Count reached")
            break
        end
        # println("===")
        push!(passed_nodes, current_node)
        push!(passed_elements, current_element)

        # get the next node
        next_node = elements[current_element][2]
        #just in case the order of the node is repeated, switch into another side of the element.
        if current_node == next_node
            next_node = elements[current_element][1]
        end
        @assert current_node ∈ elements[current_element]
        @assert next_node ∈ elements[current_element]


        #update the areas of the passed elements in node_element_area dictionary

        #find index of the current_element in node_element_index[current_node]
        current_element_idx = [i for i in eachindex(node_element_index[current_node]) if node_element_index[current_node][i] == current_element][1]
        @assert current_element == node_element_index[current_node][current_element_idx]

        #update the area of the current element
        node_element_area[current_node][current_element_idx] = node_element_area[current_node][current_element_idx] .- fixed_area

        # do the same thing for the other side of the element
        current_element_idx = [i for i in eachindex(node_element_index[next_node]) if node_element_index[next_node][i] == current_element][1]
        @assert current_element == node_element_index[next_node][current_element_idx]
        node_element_area[next_node][current_element_idx] = node_element_area[next_node][current_element_idx] .- fixed_area

        # now we are ready to move on to the next node.

        possible_areas = node_element_area[next_node]
        println(possible_areas)
        # stop if there's no possible nodes anymore
        if sum(possible_areas.>0) == 0
            println("no more elements to go")
            break
        end

        #next possible elements
        possible_elements_raw = node_element_index[next_node]
        possible_elements = possible_elements_raw[possible_areas .> 0]
        diff_areas = possible_areas .- fixed_area
        if maximum(diff_areas) < 0 
            println("no more elements to go")
            break
        end
        println(possible_elements)
        println("diff_areas",diff_areas)
        #get the element that has the biggest different area
        next_element = Int(possible_elements_raw[argmax(diff_areas)])
        @assert next_element ∈ possible_elements

        current_element = next_element
        current_node = next_node
    end

    push!(passed_nodes, current_node)
    push!(passed_elements, current_element)
    return passed_nodes, passed_elements
end
