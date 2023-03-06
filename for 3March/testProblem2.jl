using TopOpt
using Makie, GLMakie
using TopOpt.TrussTopOptProblems.TrussVisualization: visualize
using JSON
using ColorSchemes


# Data input

node_points, elements, mats, crosssecs, fixities, load_cases = 
    load_truss_json(joinpath(@__DIR__, "testfile2.json"))
ndim, nnodes, ncells = 
    length(node_points[1]), length(node_points), length(elements)
loads = load_cases["0"]
problem = TrussProblem(
    Val{:Linear}, node_points, elements, loads, fixities, mats, crosssecs
)
println("This problem has ", nnodes, " nodes and ", ncells, " elements.")
fc′ = 30. # concrete strength

list_of_areas = ones(ncells,1)[:,1]

xmin = 0.0001
solver = FEASolver(Direct, problem; xmin=xmin)
solver.vars = list_of_areas
solver()
ts = TrussStress_mod(solver)
σ =ts(PseudoDensities(list_of_areas))

color_per_cell = abs.(σ.*list_of_areas)
fig1 = visualize(
            problem, u = fill(0.1, nnodes*ndim), topology=list_of_areas,
            default_exagg_scale=0.0
            ,default_element_linewidth_scale = 5.0
            ,default_load_scale = 0.5
            ,default_support_scale = 0.1
            ,cell_colors = color_per_cell
           ,colormap = ColorSchemes.Spectral_10

         )
Makie.display(fig1)


"""


3-element Vector{Float64}:
     0.0
  7057.658261169252
 14115.316522338504
 
 correct numbers should be
 707
 707
 500
 
 "

"""
@params mutable struct TrussStress{T} <: AbstractFunction{T}
    σ::AbstractVector{T} # stress vector, axial stress per cell
    u_fn::Displacement
    transf_matrices::AbstractVector{<:AbstractMatrix{T}}
    fevals::Int
    maxfevals::Int
end
 function TrussStress_mod(solver::Any; maxfevals=10^8)
    println("This is modified")
    T = eltype(solver.u)
    dim = TopOptProblems.getdim(solver.problem)
    dh = solver.problem.ch.dh
    N = getncells(dh.grid)
    σ = zeros(T, N)
    transf_matrices = Matrix{T}[]
    u_fn = Displacement(solver; maxfevals)
    R = zeros(T, (2, 2 * dim))
    for (cellidx, cell) in enumerate(CellIterator(dh))
        u, v = cell.coords[1], cell.coords[2]
        # R ∈ 2 x (2*dim)
        R_coord = compute_local_axes(u, v)
        fill!(R, 0.0)
        R[1, 1:dim] = R_coord[:, 1]
        R[2, (dim + 1):(2 * dim)] = R_coord[:, 2]
        push!(transf_matrices, R)
    end
    return TrussStress(σ, u_fn, transf_matrices, 0, maxfevals)
end