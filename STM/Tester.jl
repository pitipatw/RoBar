using TopOpt

include("info_mod.jl")
include("factors.jl")
include("findPath.jl")
# Data input
node_points, elements, mats, crosssecs, fixities, load_cases = load_truss_json(joinpath(@__DIR__, "fromGH_23FEB.json"))
ndim, nnodes, ncells = length(node_points[1]), length(node_points), length(elements)
loads = load_cases["0"]

println("This problem has ", nnodes, " nodes and ", ncells, " elements.")
fc′ = 30. # concrete strength

list_of_areas = 1000*rand(0:10.,ncells,1)[:,1]
σ = rand(-20000.:1.,ncells,1)[:,1]


Amin = 0.001

# Get node-element info
node_element_index, node_element_unsum_score ,node_element_area, list_of_forces_on_nodes = nodeElementInfo(list_of_areas, σ,elements)
node_element_area = checkNodeElement(node_element_area)

#explain the structure of node_element_index and node_element_unsum_score
node_element_index

# Get node score (CCC, CCT, CTT)
score = getScore(node_element_unsum_score)

list_of_betan = getBetaN(score)

#this might be useless
elements_betan = getElementsBetan(elements, list_of_betan)
element_forces = σ .* list_of_areas
element_capacity_status = checkStrutAndTie(list_of_areas, element_forces, 30.)

node_capacity_status = checkNodes(list_of_forces_on_nodes,node_element_index, list_of_areas,fc′)

# get rid of hanging node
possible_starting_nodes = feasibleStartingPoints(node_element_area)
starting_node = possible_starting_nodes[3]
result = findPath(node_element_area, node_element_index,elements, starting_node)
passed_points = result[1]
passed_elements = result[2]

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

list_of_areas[Int.(passed_elements)]
passed_element_areas
using Makie, GLMakie


#This is for visualization
f = Figure(resolution = (800, 800))
ax = Axis3(f[1, 1], title = "Truss Path",
        xlabel = "x", ylabel = "y")
points = Point3f.(ptx,pty,ptz)
start_points = points[1]
end_points = points[end]
lines(points)
scatter!(ax,start_points, color = :red, markersize = 10)
scatter!(ax,end_points, color = :green, markersize = 10)
f
