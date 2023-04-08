import JSON
import GLMakie, CairoMakie

filename = "recheck_1.json"

filename = "04APR2023.json"
data = JSON.parsefile(filename)
node_points = data["node_points"]
elements = data["elements"]
areas = data["Area"]

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
    
