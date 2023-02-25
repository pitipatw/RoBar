using TopOpt

include("info_mod.jl")

# Data input
node_points, elements, mats, crosssecs, fixities, load_cases = load_truss_json(joinpath(@__DIR__, "fromGH_23FEB.json"))
ndim, nnodes, ncells = length(node_points[1]), length(node_points), length(elements)
loads = load_cases["0"]

println("This problem has ", nnodes, " nodes and ", ncells, " elements.")
fc′ = 30. # concrete strength

list_of_areas = rand(1:10.,ncells,1)[:,1]
σ = rand(-20000.:1.,ncells,1)[:,1]


Amin = 0.001

# Get node-element info
node_element, node_element_con , list_of_forces_on_nodes = nodeElementInfo(list_of_areas, σ,elements)

# Get node score (CCC, CCT, CTT)
score = getScore(node_element_con)

list_of_betan = getβn(score)

#this might be useless
elements_betan = getElementsBetan(elements, list_of_betan)
element_forces = σ .* list_of_areas
element_capacity_status = checkStrutAndTie(list_of_areas, element_forces, 30.)

node_capacity_status = checkNodes(list_of_forces_on_nodes,node_element, list_of_areas,fc′)