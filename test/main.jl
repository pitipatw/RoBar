using TopOpt, LinearAlgebra, StatsFuns
using Makie, GLMakie
using TopOpt.TrussTopOptProblems.TrussVisualization: visualize
using StaticArrays
include("Utilities.jl")
# 2D
ndim = 2

#this part is what you have to do
node_points, elements, mats, crosssecs, fixities, load_cases = load_truss_json(
    joinpath(@__DIR__, "tim_$(ndim)d2.json")
    # joinpath(@__DIR__, "fromGH.json")

)


nnx = 10 ; # number of nodes on X
nny = 10 ; # number of nodes on Y
L = 10. ;
H = 10. ;
# would be nice to able to specify the type of dict
node_points2, elements2 = groundStruct(nnx,nny,L,H) ;


ndim, nnodes, ncells = length(node_points[1]), length(node_points), length(elements)

ndim, nnodes, ncells = length(node_points2[1]), length(node_points2), length(elements2)
loads = load_cases["0"]
problem = TrussProblem(
    Val{:Linear}, node_points2, elements2, loads, fixities, mats, crosssecs
)

xmin = 0.0001 # minimum density
x0 = fill(1.0, ncells) # initial design
p = 4.0 # penalty
V = 0.8 # maximum volume fraction

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
addvar!(m, zeros(length(x0)), 2*ones(length(x0)))
# add constrain
Nonconvex.add_ineq_constraint!(m, constr)

options = MMAOptions(; maxiter=5000, tol=Tolerance(; kkt=1e-4, f=1e-4))
TopOpt.setpenalty!(solver, p)
@time r = Nonconvex.optimize(
    m, MMA87(; dualoptimizer=ConjugateGradient()), x0; options=options
)

@show obj(r.minimizer)
@show constr(r.minimizer)
fig = visualize(
    problem, solver.u, topology = r.minimizer,
    default_exagg_scale=0.0
)
Makie.display(fig)

