using TopOpt
# TopOpt v0.7.2 `https://github.com/pitipatw/TopOpt.jl#master`
using Makie, GLMakie
#using Meshes
using ColorSchemes


include("STM_info_mod.jl")
include("STM_factors.jl")
include("STM_findPath.jl")
include("STM_checkNodeElement.jl")
include("STM_postProcess.jl")
# Data input
data = JSON.parsefile("Tester_out.json"::AbstractString; dicttype=Dict, inttype=Float64, use_mmap=true)


list_of_areas_raw = convert(Array{Float64,1}, data["Area"])
σ_raw = convert(Array{Float64,1},data["Stress"])

elements_raw = data["Elements"]
elements_raw_converted = Dict{Int64, Tuple{Int64, Int64}}()
for (k,v) in elements_raw 
    elements_raw_converted[parse(Int64,k)] = Tuple{Int64, Int64}(v)
end

filter = list_of_areas_raw .> 0 

list_of_areas = list_of_areas_raw[filter]
σ = σ_raw[filter]

elements = Dict{Int64, Tuple{Int64, Int64}}()
counter = 0 
for i in eachindex(filter) 
    if filter[i] == true
        counter += 1
        elements[counter] = elements_raw_converted[i]
    end
end




# Material properties
begin
fc′ = 30. # concrete strength [MPa]
Ec = 4700.0*sqrt(fc′)
Es = 200000. # steel strength [MPa]
end

# get this from the topology optimization result (r.minimizer)


println("Inputs Pass Successfully!")


#STM starts here. 

Amin = 0.001

# Get node-element info
node_element_index, node_element_unsum_score ,node_element_area, list_of_forces_on_nodes = nodeElementInfo(list_of_areas, σ ,elements)
node_element_area = checkNodeElement(node_element_area)

#explain the structure of node_element_index and node_element_unsum_score
node_element_index

# Get node score (CCC, CCT, CTT)
score = getScore(node_element_unsum_score)

list_of_betan = getBetaN(score)

#this might be useless
elements_betan = getElementsBetan(elements, list_of_betan)
element_forces = σ .* list_of_areas
#check strut and ties capacity
element_capacity_status = checkStrutAndTie(list_of_areas, element_forces, 30.)

#check node capacity
node_capacity_status = checkNodes(list_of_forces_on_nodes,node_element_index, list_of_areas,fc′)

# get rid of hanging node

possible_starting_nodes = feasibleStartingPoints(node_element_area)

# find the Path
# Iterate every points as a starting point, and every element connected to the point as a starting element
possible_paths = Dict()
for i in eachindex(possible_starting_nodes)
    start_node = possible_starting_nodes[i]
    #get possible starting elements
    possible_start_element = node_element_index[start_node]
    for j in eachindex(node_element_index[start_node])
        starting_element = possible_start_element[j]
        result = findPath(node_element_area, node_element_index,elements, start_node)
        # passed_points = result[1] # a list of points
        # passed_elements = result[2] # a list of elements
        possible_paths[i] = result
    end
end

# now the possible_paths dictionary contains the all of the possible paths

# get each path's each element area 

# get each path's total area

#collecting the points for plot
# loop each possible path to plot
    #gonna do moving graph thing :)
for (k,v) in possible_paths
    ptx = zeros(length(v[1])) # v[1] is a list of points
    pty = zeros(length(v[1]))
    ptz = zeros(length(v[1]))
    for i in eachindex(v[1])
        ptx[i] = node_points[v[1][i]][1]
        pty[i] = node_points[v[1][i]][2]
        ptz[i] = node_points[v[1][i]][3]
    end
    f = Figure(resolution = (800, 800))
    ax = Axis3(f[1, 1], title = "Truss Path",
        xlabel = "x", ylabel = "y", zlabel = "z")
    lines!(ax, ptx, pty, ptz, color = :red, linewidth = 2)
    scatter!(ax, ptx, pty, ptz, color = :red, markersize = 10)
    display(f)
    break
end

ptx = zeros(length(passed_points))
pty = zeros(length(passed_points))
ptz = zeros(length(passed_points))
@time for i in eachindex(passed_points)
    ptx[i] = node_points[passed_points[i]][1]
    pty[i] = node_points[passed_points[i]][2]
    ptz[i] = node_points[passed_points[i]][3]
end

passed_element_areas = zeros(length(passed_elements))

for i in eachindex(passed_elements)
    passed_element_areas[i] =list_of_areas[Int(passed_elements[i])]
end



#post processing
#pushing areas to the next available size
available_sizes =  [ 1. 2. 3.][:]
mod_list_of_areas = postProcess(list_of_areas, available_sizes)
list_of_areas[Int.(passed_elements)]
passed_element_areas
#We have to check this for strain.


#This is for visualization
f = Figure(resolution = (800, 800))
ax = Axis3(f[1, 1], title = "Truss Path",
        xlabel = "x", ylabel = "y")
points = Point3f.(ptx,pty,ptz)
#points = [ptx, pty, ptz]
t = range(0, stop=1,length = length(ptx))

start_point = points[1]
end_point = points[end]
lines(points,
        colormap = ColorSchemes.magma.colors,
        color = t)
scatter!(start_point,color=:red, markersize = 10)
text!(start_point, text = "Start", color = :red)
scatter!(end_point, color = :green, markersize = 10)
text!(end_point, text = "End", color = :green)

f2 = Figure(resolution = (800, 800))
ax2 = Axis3(f2[1, 1], title = "Truss Path2",xlabel = "x", ylabel = "y")

for i in eachindex(elements)
    
    ptx1 = node_points[elements[i][1]][1]
    pty1 = node_points[elements[i][1]][2]
    ptz1 = node_points[elements[i][1]][3]
    ptx2 = node_points[elements[i][2]][1]
    pty2 = node_points[elements[i][2]][2]
    ptz2 = node_points[elements[i][2]][3]
    points = Point3f.([ptx1; ptx2] , [pty1; pty2], [ptz1; ptz2])
    println(points)
    if i in passed_elements
        println("HI")
        lines!(points,color = :red, linewidth = 50)
    else
        println("No HI")
        lines!(points,color = :black, linewidth = 10)
    end
end
f2

# this part is for plotting another plot with color as the utilization ratio
