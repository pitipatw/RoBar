using TopOpt



# Data input
node_points, elements, mats, crosssecs, fixities, load_cases = 
    load_truss_json(joinpath(@__DIR__, "2dTestProblem.json"))
ndim, nnodes, ncells = 
    length(node_points[1]), length(node_points), length(elements)
loads = load_cases["0"]
problem = TrussProblem(
    Val{:Linear}, node_points, elements, loads, fixities, mats, crosssecs
)
println("This problem has ", nnodes, " nodes and ", ncells, " elements.")
fc′ = 30. # concrete strength

list_of_areas = 5e-2*
ones(ncells,1)[:,1]

xmin = 0.0001
solver = FEASolver(Direct, problem; xmin=xmin)
σ = TrussStress(solver)(PseudoDensities(list_of_areas))




# Get node-element info
node_element, node_element_con , list_of_forces_on_nodes = nodeElementInfo(list_of_areas, σ,elements)



