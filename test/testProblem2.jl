using TopOpt
using Makie, GLMakie
using TopOpt.TrussTopOptProblems.TrussVisualization: visualize
using JSON
using ColorSchemes

"""
# problem
# 2D Truss structure with 3 nodes and 2 elements

Input JSON file name "testfile2.json"
{
    "unit": "meter",
    "materials": [
        {
            "E": 1.0,
            "name": "DummyMaterial",
            "family": "DummyMaterial",
            "elem_tags": [],
            "E_unit": "kN/m2",
            "density_unit": "kN/m3",
            "fy_unit": "kN/m2"
        }
    ],
    "dimension": 2,
    "generate_time": "06-MAR-2023",
    "elements": [
        {
            "end_node_inds": [
                0,
                1
            ],
            "elem_tag": ""
        },
        {
            "end_node_inds": [
                0,
                2
            ],
            "elem_tag": ""
        },
        {
            "end_node_inds": [
                1,
                2
            ],
            "elem_tag": ""
        }
    ],
    "supports": [
        {
            "node_ind": 0,
            "condition": [
                1,
                1
            ]
        },
        {
            "node_ind": 2,
            "condition": [
                0,
                1
            ]
        }
    ],
    "node_num": 3,
    "TO_model_type": "ground_mesh",
    "_info": "Test problem for truss_stress.jl",
    "model_name": "Pitipat",
    "element_num": 3,
    "model_type": "truss",
    "loadcases": {
        "0": {
            "ploads": [
                {
                    "node_ind": 1,
                    "force": [
                        0.0,
                        -100.0
                    ],
                    "loadcase": 0,
                    "force_unit": "kN"
                }
            ],
            "lc_ind": 0
        }
    },
    "cross_secs": [
        {
            "A": 1.0,
            "name": "",
            "family": "DummyCroSec",
            "elem_tags": [],
            "A_unit": "m2"
        }
    ],
    "nodes": [
        {
            "node_ind": 0,
            "point": [
                0.0,
                0.0
            ]
        },
        {
            "node_ind": 1,
            "point": [
                5.0,
                5.0
            ]
        },
        {
            "node_ind": 2,
            "point": [
                10.0,
                0.0
            ]
        }
    ]
}
#Draw a 3 member truss using / \ to represent the members
Truss is a 2D truss structure with 3 nodes and 3 elements
        2
        /\
   (1) /  \ (3)
      /    \
     1______3 
        (2)
    (pin)  (roller)

Point coordinates
1 -> (0,0)
2 -> (5,5)
3 -> (10,0)

Force is -100 unit in y direction at node 2

The result forces/stress (every element area = 1) in the elements are 
1 -> -70.7106 [50sqrt(2) , compression]
2 -> +50.0000 [50 , tension]
3 -> -70.7106 [50sqrt(2) , compression]
"""

result_stress = [-50*sqrt(2), 50.0000, -50*sqrt(2)]
# Data input

node_points, elements, mats, crosssecs, fixities, load_cases = 
    load_truss_json(joinpath(@__DIR__, "testfile2_compact.json"))
ndim, nnodes, ncells = 
    length(node_points[1]), length(node_points), length(elements)
loads = load_cases["0"]
problem = TrussProblem(
    Val{:Linear}, node_points, elements, loads, fixities, mats, crosssecs
)
println("This problem has ", nnodes, " nodes and ", ncells, " elements.")

x = ones(ncells,1)[:,1]

xmin = 0.0001
solver = FEASolver(Direct, problem; xmin=xmin)
ts = TrussStress(solver)
σ =ts(PseudoDensities(x))
@show σ
@assert abs(σ[1] - result_stress[1]) < 1e-12
@assert abs(σ[2] - result_stress[2]) < 1e-12
@assert abs(σ[3] - result_stress[3]) < 1e-12

color_per_cell = abs.(σ.*x)
fig1 = visualize(
            problem, u = fill(0.1, nnodes*ndim), topology=x,
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

getncells(grid::Any) = length(grid.cells)
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
        push!(transf_matrices, copy(R))
    end
    return TrussStress(σ, u_fn, transf_matrices, 0, maxfevals)
end