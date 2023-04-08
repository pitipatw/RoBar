global results = Dict()
results = data
results["Nodes"] = node_points
results["fixities"] = fixities
msg = JSON.json(results)
send(ws, msg)  

# write savepath 
savepath = joinpath(@__DIR__, "TopOpt1_out.json")

open(joinpath(@__DIR__,savepath), "w") do f
    write(f, msg)
end