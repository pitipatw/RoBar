#These are inputs
Area = rand(-1:0.01:1,1968, 1)
Amin = 0.1
σ = rand(-1:0.01:1,1968, 1)
#could cut the time by 2 by input both ends

#program starts here
node2elements = Dict()
for (k, v) in elements
    if Area[k] > Amin 
        if σ[k] > 0 #might have to add tolerance here
            # tension

            if haskey(node2elements, v[1])
                push!(node2elements[v[1]],1)
            else
                node2elements[v[1]] = [1]
            end

            if haskey(node2elements, v[2])
                push!(node2elements[v[2]],1)
            else
                node2elements[v[2]] = [1]
            end

        elseif σ[k] < 0 # also a tolerance here
            # Compression
            if haskey(node2elements, v[1])
                push!(node2elements[v[1]],0)
            else
                node2elements[v[1]] = [0]
            end

            if haskey(node2elements, v[2])
                push!(node2elements[v[2]],0)
            else
                node2elements[v[2]] = [0]
            end
        end
    end
end

@show node2elements

# return node2elements

# fuhction that get values into keys (it ran 2 times on the above funciton, could be shorter)
