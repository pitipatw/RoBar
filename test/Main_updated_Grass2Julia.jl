begin
    using HTTP.WebSockets
    using JSON
    using TopOpt #, LinearAlgebra, StatsFuns
end

#Run only if you want to visualize the results
begin
    using Makie, GLMakie
    using TopOpt.TrussTopOptProblems.TrussVisualization: visualize
    #using StaticArrays
    using ColorSchemes
end
# 10 Feb 2023
# 14 March 2023

include("GS.jl")
GLMakie.activate!(inline=false)
#add LinearAlgebra
server = WebSockets.listen!("127.0.0.1", 2000) do ws
    for msg in ws
        println("==============================")
        println("Hello, we meet again :)")
        #read stage info from JSON
        data = JSON.parse(msg)
        stage = data["stage"]
        date = data["date"]
        filename = date * "Muddy"

        if stage == "GS"
            println("Entering GroundStructure creation stage...")
            #create ground structure here.
            node_points = Dict{Int64,Vector{Float64}}()
            node_dummy = data["nodes"]
            for i in eachindex(node_dummy)
                node_points[parse(Int64, i)] = Vector{Float64}(node_dummy[i])
            end
            Lmax = data["Lmax"]

            GS = getGS(node_points, Lmax)
            #write GS to JSON
            msg = JSON.json(GS)
            println("Ground Structure created!")
            println("=================================")
            send(ws, msg)
        elseif stage == "Opt"
            println("Entering Topology Optimization stage...")
            open(joinpath(@__DIR__, filename * ".json"), "w") do f
                write(f, msg)
            end
            println("A json file written Successfully")

            node_points, elements, mats, crosssecs, fixities, load_cases = load_truss_json(joinpath(@__DIR__, filename * ".json"))

            ndim, nnodes, ncells = length(node_points[1]), length(node_points), length(elements)
            loads = load_cases["0"]
            problem = TrussProblem(
                Val{:Linear}, node_points, elements, loads, fixities, mats, crosssecs
            )
            println("Inputs Pass Successfully!")

            # To do : make a function out of this
            #Get element length 
            elements_L = zeros(ncells)
            for i in eachindex(elements)
                element = elements[i]
                node1 = node_points[element[1]]
                node2 = node_points[element[2]]
                elements_L[i] = norm(node1 .- node2)
            end


            # setting up the problem
            xmin = 0.0001 # minimum density
            V = data["maxVf"]

            x0 = V .* fill(1, ncells) # initial design
            # might not work on every objective function.
            # change to 1.0, and allow upper boundary for x,
            # so it reflects the actual cross sections area.
            p = 4.0 # penalty

            solver = FEASolver(Direct, problem; xmin=xmin)
            comp = TopOpt.Compliance(solver)

            function obj(x)
                # minimize compliance
                return comp(PseudoDensities(x))
            end
            function constr(x)
                # volume fraction constraint
                return sum(x .* elements_L) / sum(elements_L) - V
            end

            # to do 
            # stress constraints, concrete for compression, steel for tension.

            # setting upmodel
            m = Model(obj)
            #add variable boundary (model , lower bound, upper bound)
            addvar!(m, zeros(length(x0)), ones(length(x0)))
            # add constrain
            Nonconvex.add_ineq_constraint!(m, constr)
            options = MMAOptions(; maxiter=1000, tol=Tolerance(; kkt=1e-3, f=1e-3))
            TopOpt.setpenalty!(solver, p)

            # Run the optimization
            @time r = Nonconvex.optimize(
                m, MMA87(; dualoptimizer=ConjugateGradient()), x0; options=options
            )
            # Set r to global, so r could be checked again later.
            println("Optimization finished!")
            global r
            @show obj(r.minimizer)
            @show constr(r.minimizer)

            ts = TrussStress(solver)
            σ1 = ts(PseudoDensities(r.minimizer))
            color = [σ1[i] > 0 ? 1 : -1 for i in eachindex(σ1)]
            id = 0:1:(length(x0)-1)
            global results = Dict()

            # create JSON to send back the information
            results["Area"] = r.minimizer
            results["Stress"] = σ1
            results["Elements"] = elements
            results["Nodes"] = node_points
            msg = JSON.json(results)
            send(ws, msg)

            # write savepath 
            savepath = joinpath(@__DIR__, filename * "_out.json")
            # save
            open(joinpath(@__DIR__, savepath), "w") do f
                write(f, msg)
            end
            println("json output file written Successfully")

            #Truss visualization
            fig = visualize(
                problem; u=solver.u, topology=r.minimizer, cell_colors=color,
                colormap=ColorSchemes.brg,
                default_exagg_scale=0.0, default_support_scale=0.0
            )
            Makie.display(fig)

        end
    end
end


close(server)