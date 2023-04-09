function eulerian_path_undirected(graph)
    @show degree = sum(graph, dims=1)
    @show start = findfirst(degree .% 2 .!= 0)
    if start === nothing
        start = 1
    end
    visited = falses(size(graph, 1))
    path = []
    dfs_undirected(graph, start, visited, path)
    return path
end

function dfs_undirected(graph, node, visited, path)
    visited[node] = true
    for i in eachindex(graph[node, :])
        if graph[node, i] > 0 && !visited[i]
            dfs_undirected(graph, i, visited, path)
        end
    end
    push!(path, node)
end