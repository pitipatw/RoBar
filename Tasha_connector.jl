using HTTP.WebSockets
using JSON
using TopOpt, LinearAlgebra, StatsFuns
using Makie, GLMakie
using TopOpt.TrussTopOptProblems.TrussVisualization: visualize
using StaticArrays
using ColorSchemes




            
node_points, elements, mats, crosssecs, fixities, load_cases = load_truss_json(joinpath(@__DIR__, "tasha.json"))

ndim, nnodes, ncells = length(node_points[1]), length(node_points), length(elements)
loads = load_cases["0"]
problem = TrussProblem(
    Val{:Linear}, node_points, elements, loads, fixities, mats, crosssecs
)
println("Inputs Pass Successfully!")

#Get element length 
elements_L = zeros(ncells)
for i in 1:length(elements)
    element = elements[i]
    node1 = node_points[element[1]]
    node2 = node_points[element[2]]
    elements_L[i] = norm(node1 .- node2)
end



xmin = 0.0001 # minimum density
V =200
x0 = fill(1.0, ncells) # initial design
p = 4.0 # penalty
# V = 0.1 # maximum volume fraction


solver = FEASolver(Direct, problem; xmin=xmin)
comp = TopOpt.Compliance(solver)

function obj(x)
    # minimize compliance
    return comp(PseudoDensities(x))
end
function constr(x)
    # volume fraction constraint
    return sum(x .* elements_L) - V
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
global r
@show obj(r.minimizer)
@show constr(r.minimizer)
ts = TrussStress(solver)
σ1 = ts(PseudoDensities(r.minimizer))
color = [σ1[i]>0 ? 1 : -1 for i in 1:length(σ1)]
id = 0:1:(length(x0)-1)
global results = Dict()
results["Area"] =  r.minimizer
results["Stress"] = σ1
send(ws, JSON.json(results))  
#open(joinpath(@__DIR__,"\\output\\", filename * "_out.json"), "w") do f
#    write(f, msg)
#end
fig = visualize(
    problem; u =solver.u, topology=r.minimizer, cell_colors = color, 
    colormap = ColorSchemes.brg,
    default_exagg_scale=0.0 #,default_element_linewidth_scale = 3.0
    ,default_support_scale = 0.0
    )
Makie.display(fig)

send(ws, "Im back!")    
end
end
end
end

close(server)
