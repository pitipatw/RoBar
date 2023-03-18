# using TopOpt
# TopOpt v0.7.2 `https://github.com/pitipatw/TopOpt.jl#master`
using Makie, GLMakie, CairoMakie
using JSON
#using Meshes
using ColorSchemes


include("STM_info_mod.jl")
include("STM_factors.jl")
include("STM_findPath.jl")
include("STM_checkNodeElement.jl")
include("STM_postProcess.jl")
# Data input
filename = "TopOpt1_out"
data = JSON.parsefile(filename*".json"::AbstractString; dicttype=Dict, inttype=Float64, use_mmap=true)
#we also need nodepoint!!!!!!!!!
node_points_raw = data["Nodes"]
node_points = Dict{Int64, Tuple{Float64,Float64,Float64}}()
for (k,v) in node_points_raw 
    node_points[parse(Int64,k)] = Tuple{Float64,Float64,Float64}(v)
end

# node_points, elements, mats, crosssecs, fixities, load_cases = load_truss_json(joinpath(@__DIR__, "Tester_ver2.json"))
list_of_areas_raw = convert(Array{Float64,1}, data["Area"])
σ_raw = convert(Array{Float64,1},data["Stress"])

elements_raw = data["Elements"]
elements_raw_converted = Dict{Int64, Tuple{Int64, Int64}}()
for (k,v) in elements_raw 
    elements_raw_converted[parse(Int64,k)] = Tuple{Int64, Int64}(v)
end

list_of_areas = list_of_areas_raw[list_of_areas_raw .> 0 ]
σ = σ_raw[list_of_areas_raw .> 0 ]

elements = Dict{Int64, Tuple{Int64, Int64}}()
counter = 0 
filter1 = list_of_areas_raw .> 0
for i in eachindex( filter1 ) 
    if filter1[i] == true
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
#visualize the plot before and after checkNodeElement

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

#this is for findPath version2
fixed_area =  0.3
possible_paths = Dict()
for i in eachindex(possible_starting_nodes)
    start_node = possible_starting_nodes[i]
    #get possible starting elements
    possible_start_element = node_element_index[start_node]
    for j in eachindex(node_element_index[start_node])
        start_element = Int(possible_start_element[j])
        # println("start node: ", start_node)
        # println("Start element: ", start_element)
        # result = findPath(node_element_area, node_element_index,elements, start_node,start_element)
        println("startfindingpath2")
        result = findPath2(node_element_area, node_element_index,elements, start_node,start_element, fixed_area)
        println("endfindingpath2")
        # passed_points = result[1] # a list of points
        # passed_elements = result[2] # a list of elements
        possible_paths[(i,j)] = result
    end
end

println("Number of possible Paths: ", length(possible_paths))

# now the possible_paths dictionary contains the all of the possible paths
Makie.inline!(false)


begin
f = Makie.Figure(resolution = (1000, 1000));
#collecting the points for plot
# loop each possible path to plot
    #gonna do moving graph thing :)
nr = 5
nc = 5
track_row = 1
track_col = 1 
plt_counter = 0

for (k,v) in possible_paths
    # if plt_counter > track_row*track_col
        
    #reset ptx pty ptz
    ptx = zeros(length(v[1])) # v[1] is a list of points
    pty = zeros(length(v[1]))
    ptz = zeros(length(v[1]))
    for i in eachindex(v[1])
        println("i: ", i)
        println("v[1][i]: ", v[1][i])
        ptx[i] = node_points[v[1][i]][1]
        pty[i] = node_points[v[1][i]][2]
        ptz[i] = node_points[v[1][i]][3]
    end
    ax = Axis3(f[track_row, track_col], title = "Truss Path $k",
    xlabel = "x", ylabel = "y", zlabel = "z", aspect = (1,1/2,1))

    ax.azimuth[] = -pi/2
    ax.elevation = pi/2

    # t is for color
    t = range(0, stop=1,length = length(ptx))

    lines!(ax, ptx, pty, ptz, color = t, linewidth = 3, 
        colormap = ColorSchemes.magma.colors)

    start_point = (ptx[1] , pty[1] , ptz[1])
    end_point   = (ptx[end] , pty[end] , ptz[end])

    # println("Start Point: ", start_point)
    # println("End Point: ", end_point)

    scatter!(ax, start_point, color=:red, markersize = 15)
    #text!(ax,start_point, text = "Start", color = :red)
    scatter!(ax, end_point, color = :green, markersize = 10)
    #text!(ax,end_point, color = :green , text = "End")

    #plot entire truss
    for (k0,v0) in elements
        x1 = node_points[v0[1]][1]
        y1 = node_points[v0[1]][2]
        z1 = node_points[v0[1]][3]
        x2 = node_points[v0[2]][1]
        y2 = node_points[v0[2]][2]
        z2 = node_points[v0[2]][3]
        lines!(ax, [x1,x2], [y1,y2], [z1,z2], color = :gray, linewidth = 0.5)
    end
    if track_col == nc
        if track_row == nr
            break
        end
        track_row += 1
        track_col = 1
    else
        track_col += 1
    end

end
cb = Colorbar(f[:, nc+1] ,colormap = ColorSchemes.magma.colors )
display(f)
end

display(f)
# ptx = zeros(length(passed_points))
# pty = zeros(length(passed_points))
# ptz = zeros(length(passed_points))
# @time for i in eachindex(passed_points)
#     ptx[i] = node_points[passed_points[i]][1]
#     pty[i] = node_points[passed_points[i]][2]
#     ptz[i] = node_points[passed_points[i]][3]
# end

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
