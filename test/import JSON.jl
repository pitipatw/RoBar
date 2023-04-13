import JSON
import Makie, GLMakie #, CairoMakie

filename = "04APR2023.json"
data = JSON.parsefile(filename)

areas = data["areas"]
elements = data["elements"]
node_points = data["node_points"]

ne = length(elements)
figure1 = GLMakie.Figure(resolution = (1200, 800), 
            backgroundcolor = :white);

#create axis for every elements with nrow row
nrow =10
for i in 1:ne
    @show r = i%(nrow)
    if r == 0 ; r = nrow ; end
    c = div(i,nrow) + 1
    #xlim and ylim are [10 and 2]

    ax = GLMakie.Axis(figure1[r,c], xlabel="x", ylabel="y" , 
    yticklabelsvisible = false, xticklabelsvisible = false);
    GLMakie.xlims!(ax, -0.1,10.1)
    GLMakie.ylims!(ax, -0.1,2.1)
    element = elements[string(i)]

    node1 = node_points[string(element[1])]
    node2 = node_points[string(element[2])]
    x1 = node1[1]
    y1 = node1[2]
    x2 = node2[1]
    y2 = node2[2]
    GLMakie.lines!(ax, [x1,x2], [y1,y2], color = :black)
end
Makie.inline!(false);
display(figure1)
#loop and plot every element in each ax