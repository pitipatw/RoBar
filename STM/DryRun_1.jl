using TopOpt
# TopOpt v0.7.2 `https://github.com/pitipatw/TopOpt.jl#master`
using Makie, GLMakie
using Meshes
using ColorSchemes


include("info_mod.jl")
include("factors.jl")
include("findPath.jl")
include("checkNodeElement.jl")
include("postProcess.jl")
# Data input
node_points, elements, mats, crosssecs, fixities, load_cases = load_truss_json(joinpath(@__DIR__, "fromGH_23FEB.json"))
ndim, nnodes, ncells = length(node_points[1]), length(node_points), length(elements)
loads = load_cases["0"]

println("This problem has ", nnodes, " nodes and ", ncells, " elements.")
# Material properties
fc′ = 30. # concrete strength [MPa]
Es = 200000. # steel strength [MPa]

# get this from the topology optimization result (r.minimizer)


problem = TrussProblem(
    Val{:Linear}, node_points, elements, loads, fixities, mats, crosssecs
)
println("Inputs Pass Successfully!")
xmin = 0.0001 # minimum density
x0 = fill(1.0, ncells) # initial design
p = 4.0 # penalty
# V = 0.1 # maximum volume fraction
V = 0.2

solver = FEASolver(Direct, problem; xmin=xmin)
comp = TopOpt.Compliance(solver)

function obj(x)
    # minimize compliance
    return comp(PseudoDensities(x))
end
function constr(x)
    # volume fraction constraint
    return sum(x) / length(x) - V
end

# setting upmodel
m = Model(obj)
#add variable boundary (model , lb, ub)
addvar!(m, zeros(length(x0)), ones(length(x0)))
# add constrain
Nonconvex.add_ineq_constraint!(m, constr)

options = MMAOptions(; maxiter=1000, tol=Tolerance(; kkt=1e-4, f=1e-4))
TopOpt.setpenalty!(solver, p)
@time r = Nonconvex.optimize(
    m, MMA87(; dualoptimizer=ConjugateGradient()), x0; options=options
)

@show obj(r.minimizer)
@show constr(r.minimizer)

solver = FEASolver(Direct, problem; xmin=xmin)
ts = TrussStress(solver)
σ =ts(PseudoDensities(r.minimizer))

list_of_areas = r.minimizer


#STM starts here. 

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
starting_node = possible_starting_nodes[1]
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

available_sizes =  [ 1. 2. 3.][:]
mod_list_of_areas = postProcess(list_of_areas, available_sizes)
list_of_areas[Int.(passed_elements)]
passed_element_areas

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
