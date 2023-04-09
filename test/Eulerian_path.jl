function eulerian_path_undirected(graph)
    degrees = sum(graph, dims=1)
    odd_degrees = findall(x -> x % 2 != 0, degrees)
    if length(odd_degrees) > 2
        return [] # No Eulerian path exists
    end
    start = (length(odd_degrees) == 2) ? odd_degrees[1] : 1
    path = []
    dfs_undirected(graph, start, path)
    return path
end

function dfs_undirected(graph, node, path)
    while sum(graph[node, :]) > 0
        next_node = findfirst(graph[node, :] .> 0)
        graph[node, next_node] -= 1
        graph[next_node, node] -= 1
        dfs_undirected(graph, next_node, path)
    end
    push!(path, node)
end