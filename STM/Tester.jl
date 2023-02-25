using TopOpt

include("info_mod.jl")


node_points, elements, mats, crosssecs, fixities, load_cases = load_truss_json(joinpath(@__DIR__, "fromGH_23FEB.json"))
ndim, nnodes, ncells = length(node_points[1]), length(node_points), length(elements)
loads = load_cases["0"]

nnodes
ncells
#Create vector of Area and σ with length of elements = 1968
#create 1 by 1968 vector of Float64 with random values from -1 to 1
# initial design
list_of_areas = rand(-10.:10.,ncells,1)[:,1]
σ = rand(-2.:2.,ncells,1)[:,1]


#vec = Vector{Float64}(undef, 1968)


Amin = 0.1

#create vector of length with random numbers


node_element_info = nodeElementInfo(list_of_areas, σ,elements)
score = getScore(node_element_info)
#get key of score that has value more than 0
key = findall(x -> x > 0, score)
#get multiple values of score from key
score[key]

list_of_betan = getβn(score)

elements_betan = getElementsBetan(elements, list_of_betan)