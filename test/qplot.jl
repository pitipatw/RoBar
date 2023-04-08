import JSON
import GLMakie, CairoMakie

filename = "recheck_1.json"

filename = "04APR2023.json"
data = JSON.parsefile(filename)
node_points = data["node_points"]
elements = data["elements"]

begin
    node_points_raw = data["node_points"]
    node_points = Dict{Int64, Tuple{Float64,Float64,Float64}}()
    for (k,v) in node_points_raw 
        node_points[parse(Int64,k)] = Tuple{Float64,Float64,Float64}(v)
    end
end
sorted_node_points = sort(collect(node_points))
begin
    elements_raw = data["elements"] ;
    elements_raw_converted = Dict{Int64, Tuple{Int64, Int64}}();
    for (k,v) in elements_raw 
        elements_raw_converted[parse(Int64,k)] = Tuple{Int64, Int64}(v) ;
    end
end
sorted_elements = sort(collect(elements_raw_converted))


results = Dict()
int_nodes = Tuple{Float64, Float64, Float64}[]
for (k,v) in sorted_node_points
    push!(int_nodes, Tuple{Float64,Float64,Float64}(v))
end

int_elements = Tuple{Int64, Int64}[]
for (k,v) in sorted_elements
    push!(int_elements, Tuple{Int64, Int64}(v))
end

results["Area"] = areas
results["elements"] = int_elements
results["nodes"] = int_nodes

open(joinpath(@__DIR__,"0704.json"), "w") do f
    write(f,JSON.json(results)
    )
end

figure2 = GLMakie.Figure(resolution = (1800, 800), backgroundcolor = :white)
ax = GLMakie.Axis(figure2[1,1] , xlabel = "x", ylabel = "y" )
for i in eachindex(int_elements)
    element = int_elements[i]
    p1 = element[1]
    p2 = element[2]
    
    x1 = int_nodes[p1][1]
    y1 = int_nodes[p1][2]
    x2 = int_nodes[p2][1]
    y2 = int_nodes[p2][2]
    GLMakie.lines!(ax, figure2[1,1], [x1, x2], [y1, y2], color = :blue)
end


areas = data["areas"]

figure = GLMakie.Figure(resolution = (1800, 800), backgroundcolor = :white)
axis1 = GLMakie.Axis(figure[1,1] , xlabel = "x", ylabel = "y" )
axis1.xticks = 0:1:10
for i in eachindex(elements) 
    # println(typeof(i))
    element = elements[i]
    p1 = element[1] 
    p2 = element[2] 

    x1 = node_points[string(Int(p1))][1]
    y1 = node_points[string(Int(p1))][2]
    # z1 = node_points[p1][3]
    x2 = node_points[string(Int(p2))][1]
    y2 = node_points[string(Int(p2))][2]
    # z2 = node_points[p2][3]

    i = parse(Int64,i)
    lw = areas[i]
    GLMakie.lines!(axis1, [x1, x2], [y1, y2], color = :blue, linewidth = (areas[i]))
end
# GLMakie.ylims!(0, 2)

show(figure)
    
