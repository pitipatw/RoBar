using TopOpt
include("/info_mod.jl")
Area = rand(-1:0.01:1,1968, 1)
Amin = 0.1
σ = rand(-1:0.01:1,1968, 1)

nodeElementInfo = node_element_info(Area, σ)

