"""
This function pushes the size of the elements into the next available area size.
areas is a vector that contains the areas of the whole structure sorted by element indexees.
set_areas is a vector that contains the available area sizes "from the smallest to the largest" value
"""
function postProcess(areas::Vector{Float64} , set_areas::Vector{Float64})
    processed_areas = copy(areas)
    for i in eachindex(areas)
        initial_area = areas[i]
        if initial_area < set_areas[1]
            processed_areas[i] = set_areas[1]
        elseif initial_area > set_areas[end]
            println("Area of element $i is greater than the largest area size. It is set to the original size [UNCHANGE]")
        else
            for j in 2:(length(set_areas)-1)
                if (initial_area > set_areas[j]) && (initial_area <= set_areas[j+1])
                    processed_areas[i] = set_areas[j+1]
                    break
                end
            end
        end
        println(initial_area, " -> ", processed_areas[i])
    end
    return processed_areas
end

# #create vector of 0 to 1000 with step 1
# x = collect(0.:1.:150.)
# x_set = [ 5. 10. 30. 35. 45. 100. 125. 130. 145. 2010.][:]
# b = postProcess(x, x_set)
# cc = postProcess([100.], x_set)

# f = Figure(resolution = (800, 800))
# ax = Axis(f[1, 1], title = "Truss Path",
#         xlabel = "x")
# Makie.scatter(x, b, color = :red, markersize = 10)