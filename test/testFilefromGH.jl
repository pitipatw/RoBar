using TopOpt
using Makie, GLMakie
using TopOpt.TrussTopOptProblems.TrussVisualization: visualize
using HTTP.WebSockets




filename = "testfile1fromGH.json"
filename = 
path_testfile = joinpath(@__DIR__, filename)


server = WebSockets.listen!("127.0.0.1", 2000) do ws
    for msg in ws
        println("Hello there :)")
        open(path_testfile, "w") do f
            write(f, msg)
        end
        println("TestFileCreated")
        send(ws, "TestFileCreated")
    end
end
close(server)