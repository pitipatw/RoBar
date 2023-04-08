"""
From node_elements:
check if the number of elements is greater than 3 or not?
If the number of elements connected to the node is less than 3,
change the area of those nodes into 0

node_element_area
Dict{Int64, Vector{Float64}} with 8 entries:
node # -> area of each element connected to the node
5 => [9.0, 6.0, 7.0, 5.0, 5.0, 7.0]
4 => [9.0, 8.0, 9.0, 10.0, 1.0, 4.0]
6 => [7.0, 7.0, 5.0, 8.0, 7.0, 5.0]
7 => [2.0, 8.0, 8.0, 2.0, 4.0, 7.0]
2 => [9.0, 10.0, 3.0, 5.0, 8.0, 5.0]
8 => [6.0, 2.0, 10.0, 5.0, 3.0, 6.0]
3 => [8.0, 6.0, 8.0, 7.0, 2.0, 9.0]
1 => [7.0, 10.0, 8.0, 1.0, 5.0, 9.0]
"""
function removeHanging(node_element_index,node_element_area)
    #create a copy of the node_element_area to modify
    # mod_node2elements = deepcopy(node_element_index)
    mod_node2element_areas = deepcopy(node_element_area)
    #loop each node
    for (k,v) in node_element_area
        #check if the number of the non-zera element connected to the node
        #is >= 3
        if sum(v.>0) < 3
            # pop!(mod_node2element_areas, k)
            # pop!(mod_node2elements, k)
            # #if less than 3, change the area of those elements to 0
            for j in eachindex(node_element_area[k])
                mod_node2element_areas[k][j] = 0.
            end
        end
    end
    return mod_node2element_areas
end


