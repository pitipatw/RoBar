"""
This file will be used with first of 3 march file
"""


using TopOpt
using Makie, GLMakie
using TopOpt.TrussTopOptProblems.TrussVisualization: visualize
using JSON
using ColorSchemes

filename = "testfile1.json"
path_testfile = joinpath(@__DIR__, filename)
node_points, elements, mats, crosssecs, fixities, load_cases =
                             load_truss_json(path_testfile)
ndim, nnodes, ncells = length(node_points[1]), length(node_points), length(elements)
loads = load_cases["0"]
problem = TrussProblem(
    Val{:Linear}, node_points, elements, loads, fixities, mats, crosssecs
)


xmin = 0.0001
solver = FEASolver(Direct, problem; xmin=xmin)


begin
x0 = fill(10., ncells)
println(x0)
σ = TrussStress(solver)(PseudoDensities(x0))
println("this is stress: ", σ)
color_per_cell = abs.(σ.*x0)
println("this is forces", σ.*x0)
end
fig1 = visualize(
            problem, u = fill(0.1, nnodes*ndim), topology=x0,
            default_exagg_scale=0.0
            ,default_element_linewidth_scale = 5.0
            ,default_load_scale = 0.5
            ,default_support_scale = 0.1
            ,cell_colors = color_per_cell
           ,colormap = ColorSchemes.Spectral_10

         )
Makie.display(fig1)

