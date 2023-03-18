begin
    using HTTP.WebSockets
    using JSON
    using TopOpt #, LinearAlgebra, StatsFuns
end

#Run only if you want to visualize the results
begin
    using Makie, GLMakie
    using TopOpt.TrussTopOptProblems.TrussVisualization: visualize
    #using StaticArrays
    using ColorSchemes
end
# 10 Feb 2023
# 14 March 2023



filename = "test_noWeb"
println("Entering Topology Optimization stage...")


node_points, elements, mats, crosssecs, fixities, load_cases = load_truss_json(joinpath(@__DIR__, filename * ".json"))

ndim, nnodes, ncells = length(node_points[1]), length(node_points), length(elements)
loads = load_cases["0"]
problem = TrussProblem(
    Val{:Linear}, node_points, elements, loads, fixities, mats, crosssecs
)
println("Inputs Pass Successfully!")

# To do : make a function out of this
#Get element length 
elements_L = zeros(ncells)
for i in eachindex(elements)
    element = elements[i]
    node1 = node_points[element[1]]
    node2 = node_points[element[2]]
    elements_L[i] = norm(node1 .- node2)
end


# setting up the problem
xmin = 0.0001 # minimum density
V = data["maxVf"]

x0 = fill(0.5, ncells) # initial design
# might not work on every objective function.
# change to 1.0, and allow upper boundary for x,
# so it reflects the actual cross sections area.
p = 4.0 # penalty

solver = FEASolver(Direct, problem; xmin=xmin)
comp = TopOpt.Compliance(solver)

function obj(x)
    # minimize compliance
    return comp(PseudoDensities(x))
end
function constr(x)
    # volume fraction constraint
    return sum(x .* elements_L) / sum(elements_L) - V
end

# to do 
# stress constraints, concrete for compression, steel for tension.

# setting upmodel
m = Model(obj)
#add variable boundary (model , lower bound, upper bound)
addvar!(m, zeros(length(x0)), ones(length(x0)))
# add constrain
Nonconvex.add_ineq_constraint!(m, constr)
options = MMAOptions(; maxiter=1000, tol=Tolerance(; kkt=1e-4, f=1e-4))
TopOpt.setpenalty!(solver, p)

# Run the optimization
@time r = Nonconvex.optimize(
    m, MMA87(; dualoptimizer=ConjugateGradient()), x0; options=options
)
# Set r to global, so r could be checked again later.
global r
@show obj(r.minimizer)
@show constr(r.minimizer)

ts = TrussStress(solver)
σ1 = ts(PseudoDensities(r.minimizer))
color = [σ1[i] > 0 ? 1 : -1 for i in eachindex(σ1)]
id = 0:1:(length(x0)-1)
global results = Dict()

# create JSON to send back the information
results["Area"] = r.minimizer
results["Stress"] = σ1
results["Elements"] = elements
msg = JSON.json(results)
send(ws, msg)

# write savepath 
savepath = joinpath(@__DIR__, filename * "_out.json")
# save
open(joinpath(@__DIR__, savepath), "w") do f
    write(f, msg)
end
println("json output file written Successfully")

#Truss visualization
fig = visualize(
    problem; u=solver.u, topology=r.minimizer, cell_colors=color,
    colormap=ColorSchemes.brg,
    default_exagg_scale=0.0, default_support_scale=0.0
)
Makie.display(fig)

println("Optimization finished!")

