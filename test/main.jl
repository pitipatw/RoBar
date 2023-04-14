# using TopOpt
# TopOpt v0.7.2 `https://github.com/pitipatw/TopOpt.jl#master`
using Makie, GLMakie #,CairoMakie
using JSON
#using Meshes
using ColorSchemes

# Get node-element info
mutable struct Node
    x::Float64
    y::Float64
    z::Float64
    elements::Vector{Int64}
    score::Vector{Int64}
    areas::Vector{Float64}
    forces::Vector{Float64}
end

begin
    include("STM_info_mod.jl")
    include("STM_factors.jl")
    include("STM_findPath.jl")
    include("STM_postProcess.jl")
end

# Data input
filename = "Kuka1_out"
"""
Data Fields
Area : A list of areas for each element
Nodes : A dictionary, "5" : [x, y ,z] (string -> list of floats)
Elements : A dictionary, "element num" : [start end idx in floats]
Stress : A list of stresses for each element
"""
data = JSON.parsefile(filename*".json"::AbstractString; dicttype=Dict, inttype=Float64, use_mmap=true)

# turn Node_points into Int64 -> [Floats] format.
begin
    node_points_raw = data["Nodes"]
    node_points = Dict{Int64, Tuple{Float64,Float64,Float64}}()
    for (k,v) in node_points_raw 
        node_points[parse(Int64,k)] = Tuple{Float64,Float64,Float64}(v)
    end
end

# node_points, elements, mats, crosssecs, fixities, load_cases = load_truss_json(joinpath(@__DIR__, "Tester_ver2.json"))
areas = convert(Array{Float64,1}, data["Area"]) ;
σ_raw = convert(Array{Float64,1},data["Stress"]) ;

# turn elements into Int64 -> Int64 format.


area_filter = areas .> 0 ;
pos_areas = areas[area_filter] ;
σ = σ_raw[areas .> 0 ] ;
# begin
#     elements_raw = data["Elements"] ;
#     elements_raw = Dict{Int64, Tuple{Int64, Int64}}();
#     for (k,v) in elements_raw 
#         elements_raw_converted[parse(Int64,k)] = Tuple{Int64, Int64}(v) ;
#     end
# end

elements = Dict{Int64, Tuple{Int64, Int64}}()
global counter = 0 
elements_raw = data["Elements"]
for i in eachindex( area_filter ) 
    if area_filter[i] == true
        global counter += 1
        @show string(i)
        elements[counter] = Tuple{Int64,Int64}(elements_raw[string(i)])
    end
end

# Material properties
begin
    fc′ = 30. # concrete strength [MPa]
    Ec = 4700.0*sqrt(fc′)
    Es = 200000. # steel strength [MPa]
end

println("Inputs Pass Successfully!")

#STM starts here. 

Amin = 0.0001



Nodes = Dict{Int64, Node}();
for i in eachindex(node_points)
    x = node_points[i][1]
    y = node_points[i][2]
    z = node_points[i][3]
    els = Vector{Int64}()
    sc  = Vector{Int64}()
    a   = Vector{Float64}()
    fs  = Vector{Float64}()
    check = false
    for j in eachindex(elements)
        if elements[j][1] == i || elements[j][2] == i
            push!(els, j)
            push!(a, pos_areas[j])
            if σ[j] > 0 
                push!(sc, 1)
            else 
                push!(sc, 0)
            end
            push!(fs, σ[j]*pos_areas[j])
            check = true
        end
    end
    # a = Node(x,y,z, els, sc, a, fs)
    if check
        Nodes[i] = Node(x,y,z, deepcopy(els), deepcopy(sc), deepcopy(a), deepcopy(fs))
    end
end

#node2elements, node2element_scores ,node2element_areas_raw, node2forces = nodeElementInfo(pos_areas, σ ,elements);
Nodes, mod_pos_areas = removeHanging(Nodes , pos_areas)

#visualize the plot before and after checkNodeElement
#plot the truss structure before and after the modifications. 

#plot truss structure
scale = 5.0
truss0 = Makie.Figure(resolution = (1000, 1000));
axis0 = Axis3(truss0[1,1], xlabel = "x", ylabel = "y", aspect = (4,1,1), title = "original");
axis1 = Axis3(truss0[2,1] , xlabel = "x", ylabel = "y", aspect = (4,1,1) , title = "modified"); 
Makie.inline!(false)
#axis equal
for i in eachindex(elements)
    element = elements[i]
    x1 = Nodes[element[1]].x
    y1 = Nodes[element[1]].y
    z1 = Nodes[element[1]].z

    x2 = Nodes[element[2]].x
    y2 = Nodes[element[2]].y
    z2 = Nodes[element[2]].z

    if pos_areas[i] > 0 
        # in some pos_areas position, mod_pos_areas will be 0
        if σ[i] > 0 
            
            lines!(axis0, [x1, x2], [y1, y2], [z1,z2], linewidth =pos_areas[i]*scale , color=:blue)
            lines!(axis1, [x1, x2], [y1, y2], [z1,z2],linewidth = mod_pos_areas[i]*scale, color=:blue)

        else 
            lines!(axis0, [x1, x2], [y1, y2], [z1,z2],linewidth = pos_areas[i]*scale , color=:red)
            lines!(axis1, [x1, x2], [y1, y2], [z1,z2],linewidth = mod_pos_areas[i]*scale, color=:red)
        end
    end
end

GLMakie.display(truss0)

# create JSON to send back the information
result2 = Dict()
result2["Area"] =  pos_areas
result2["Stress"] = σ
result2["Elements"] = elements
result2["Nodes"] = node_points
msg = JSON.json(result2)
# savepath 
savepath = joinpath(@__DIR__, "result2"*"_out.json")
# save
open(joinpath(@__DIR__,savepath), "w") do f
    write(f, msg)
end

### STM starts here.
#modify these guys to Node structure 
list_of_betan = getBetaN(score)

#this might be useless
elements_betan = getElementsBetan(elements, list_of_betan)
element_forces = σ .* mod_pos_areas
#check strut and ties capacity
element_capacity_status = checkStrutAndTie(mod_pos_areas, element_forces, 30.)

#check node capacity
node_capacity_status = checkNodes(node2forces,node2elements, mod_pos_areas,fc′)

# End of STM analysis.

# Start path finding

#create adjacency matrix out of Nodes

#create map from node to index, becuase node number maybe skiped
reidx = 0 
map = Dict{Int64, Int64}()
unmap = Dict{Int64, Int64}()
for i in eachindex(sort(Nodes))
    reidx += 1
    map[i] = reidx
    unmap[reidx] = i
end

adjacency_matrix = zeros(Int64, length(Nodes), length(Nodes))
for i in eachindex(sort(elements))
    if mod_pos_areas[i] > 0
    adjacency_matrix[map[elements[i][1]], map[elements[i][2]]] = 1
    adjacency_matrix[map[elements[i][2]], map[elements[i][1]]] = 1
    end
end

#plot graph using adjacency_matrix 
f = GLMakie.Figure(resolution = (1000, 1000));
ax = GLMakie.Axis(f[1,1])
for i = 1:length(Nodes)
    for j = (i+1):length(Nodes)
        if adjacency_matrix[i,j] == 1
            I = unmap[i]
            J = unmap[j]
            x1 = Nodes[I].x
            y1 = Nodes[I].y
            z1 = Nodes[I].z
            x2 = Nodes[J].x
            y2 = Nodes[J].y
            z2 = Nodes[J].z
            lines!(ax, [x1,x2], [y1,y2], [z1,z2], color = :gray)
        end
    end
end
display(f)

# I want to visit every element and node.
mod_adj = copy(adjacency_matrix)
list_of_paths = Vector{Vector{Int64}}()

# go through each node,
# for each node go through each elements. -> arrive at new node.
# remove the passed node from the matrix, both in ij and in ji. 
# for each node go through each nodes. -> arrive at new node.
# find eulerian path
function move(adjacency_matrix::Matrix{Int64}, a::Int64, b::Int64)
    adjacency_matrix[a,b] = 0
    adjacency_matrix[b,a] = 0
    return adjacency_matrix
end

using ProgressBars

list_of_paths = []
for i in eachindex(adjacency_matrix)
    count1 = 0 
    while sum(adjacency_matrix) > 0 && count1 < 100
        count1 +=1 
        path = Vector{Int64}()
        push!(path, i)
        count2 = 0
        while sum(adjacency_matrix[i,:]) > 0 && count2 < 100
            count2 += 1 
            # go through each elements
            for j in eachindex(adjacency_matrix[i,:])
                if adjacency_matrix[i,j] == 1
                    adjacency_matrix = move(adjacency_matrix, i, j)
                    push!(path, j)
                    i = j
                    break
                end
            end
        end
        push!(list_of_paths, path)
    end
end


path = eulerian_path_undirected(adjacency_matrix)
# feasible starting points are the nodes that have at least one element connected to it.
possible_starting_nodes = feasibleStartingPoints(node2element_areas)
# Makie.inline!(true)
# f0 = GLMakie.Figure(resolution = (1000, 1000));
# ax = GLMakie.Axis3(f0[1,1], aspect = :data)
# for (k0,v0) in elements
#     x1 = node_points[v0[1]][1]
#     y1 = node_points[v0[1]][2]
#     z1 = node_points[v0[1]][3]
#     x2 = node_points[v0[2]][1]
#     y2 = node_points[v0[2]][2]
#     z2 = node_points[v0[2]][3]
#     lines!(ax, [x1,x2], [y1,y2], [z1,z2], color = :gray, linewidth = 0.5)
# end
# display(f0)
# #label each node and element number
# for (k0,v0) in node_points
#     text!(ax, v0[1], v0[2], v0[3], string(k0), color = :black, textsize = 10)
# end
#label each element
# for (k0,v0) in elements
#     x1 = node_points[v0[1]][1]
#     y1 = node_points[v0[1]][2]
#     z1 = node_points[v0[1]][3]
#     x2 = node_points[v0[2]][1]
#     y2 = node_points[v0[2]][2]
#     z2 = node_points[v0[2]][3]
#     text!(ax, (x1+x2)/2, (y1+y2)/2, (z1+z2)/2, string(k0), color = :black, textsize = 10)
# end




# find the Path
# Iterate every points as a starting point, and every element connected to the point as a starting element
#this is for findPath version2
fixed_area =  0.3
possible_paths = Dict()
for i in eachindex(possible_starting_nodes)
    start_node = possible_starting_nodes[i]
    #get possible starting elements
    possible_start_elements= node2elements[start_node]
    for j in eachindex(node2elements[start_node])
        # println("j:" , j)
        # println("start_node:", start_node)
        if possible_start_elements[j] ∉ node2elements[start_node]
            println("HI")
            continue
        end
        # if node2element_areas[start_node][1] <= 0 
        #     println("HI")
        #     continue
        # end
        start_element = Int(possible_start_elements[j])
        # println("start node: ", start_node)
        # println("Start element: ", start_element)
        # result = findPath(node2element_areas, node2elements,elements, start_node,start_element)
        println("startfindingpath2")
        result = findPath2(node2element_areas, node2elements,elements, start_node,start_element, fixed_area)
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
    if length(v[1]) == 2 
        continue
    end

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
        lines!(ax, [x1,x2], [y1,y2], [z1,z2], color = :gray, linewidth = area_filter[k0])
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
    passed_element_areas[i] =pos_areas[Int(passed_elements[i])]
end



#post processing
#pushing areas to the next available size
available_sizes =  [ 1. 2. 3.][:]
mod_list_of_areas = postProcess(pos_areas, available_sizes)


pos_areas[Int.(passed_elements)]
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
