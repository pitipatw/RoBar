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


server = WebSockets.listen!("127.0.0.1", 2000) do ws
    for msg in ws
        println("Hello, we meet again :)")
        #read stage info from JSON
        data = JSON.parse(msg)
        stage = data["stage"]
        filename = "Tester"

        if stage == "GS"
            println("Entering GroundStructure creation stage...")
            #create ground structure here.
            send(ws, "Ground Structre created!")
        elseif stage == "Opt"
            println("Entering Topology Optimization stage...")
            open(joinpath(@__DIR__, filename*".json"), "w") do f
            write(f, msg)
            println("json file written Successfully")
            
            node_points, elements, mats, crosssecs, fixities, load_cases = load_truss_json(joinpath(@__DIR__, filename*".json"))

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

            x0 = fill(0.5, ncells) # initial design
            p = 4.0 # penalty
    
            solver = FEASolver(Direct, problem; xmin=xmin)
            comp = TopOpt.Compliance(solver)
            
            function obj(x)
                # minimize compliance
                return comp(PseudoDensities(x))
            end
            function constr(x)
                # volume fraction constraint
                return sum(x .* elements_L) - V
            end

            # to do 
            # stress constraints, concrete for compression, steel for tension.

            # setting upmodel
            m = Model(obj)
            #add variable boundary (model , lower bound, upper bound)
            addvar!(m, zeros(length(x0)), ones(length(x0)))
            # add constrain
            Nonconvex.add_ineq_constraint!(m, constr)
            options = MMAOptions(; maxiter=1000, tol=Tolerance(; kkt=1e-4, f=1e-4))
            TopOpt.setpenalty!(solver, p)

            # Run the optimization
            @time r = Nonconvex.optimize(
                m, MMA87(; dualoptimizer=ConjugateGradient()), x0; options=options
            )
            # Set r to global, so r could be checked again later.
            global r
            @show obj(r.minimizer)
            @show constr(r.minimizer)

            ts = TrussStress(solver)
            σ1 = ts(PseudoDensities(r.minimizer))
            color = [σ1[i]>0 ? 1 : -1 for i in eachindex(σ1)]
            id = 0:1:(length(x0)-1)
            global results = Dict()

            # create JSON to send back the information
            results["Area"] =  r.minimizer
            results["Stress"] = σ1
            results["Elements"] = elements
            msg = JSON.json(results)
            send(ws, msg)  

            # write savepath 
            savepath = joinpath(@__DIR__, filename * "_out.json")
            # save
            open(joinpath(@__DIR__,savepath), "w") do f
                write(f, msg)
            end
            println("json output file written Successfully")
            
            #Truss visualization
            fig = visualize(
                problem; u =solver.u, topology=r.minimizer, cell_colors = color, 
                colormap = ColorSchemes.brg,
                default_exagg_scale=0.0 #,default_element_linewidth_scale = 3.0
                ,default_support_scale = 0.0
                )
            Makie.display(fig)

            send(ws, "Optimization finished!")  
    
        end
    end
    end
end

close(server)
