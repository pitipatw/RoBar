begin
    using HTTP.WebSockets
    using JSON
    using TopOpt, LinearAlgebra, StatsFuns
end

begin
    using Makie, GLMakie
    using TopOpt.TrussTopOptProblems.TrussVisualization: visualize
    using StaticArrays
    using ColorSchemes
end
# 10 Feb 2023

server = WebSockets.listen!("127.0.0.1", 2000) do ws
    for msg in ws
        println("Hello there :)")
        open(joinpath(@__DIR__, "fromGH_24FEB.json"), "w") do f
            write(f, msg)
        end
        data = JSON.parse(msg)
        node_points, elements, mats, crosssecs, fixities, load_cases = load_truss_json(joinpath(@__DIR__, "fromGH_24FEB.json"))

        ndim, nnodes, ncells = length(node_points[1]), length(node_points), length(elements)
        loads = load_cases["0"]
        problem = TrussProblem(
            Val{:Linear}, node_points, elements, loads, fixities, mats, crosssecs
        )
        println("Inputs Pass Successfully!")

        xmin = 0.0001 # minimum density
        # link this to volume fraction
        V = data["maxVf"]
        x0 = fill(V, ncells) # initial design
        p = 4.0 # penalty
        # to discard the lenght, it should be linked to the heavyside function? 
        # denser Groundstructure.
        # V = 0.1 # maximum volume fraction

    
        solver = FEASolver(Direct, problem; xmin=xmin)
        comp = TopOpt.Compliance(solver)

        function obj(x)
            # minimize compliance
            return comp(PseudoDensities(x))
        end
        function constr(x)
            # volume fraction constraint
            return sum(x) / length(x) - V
        end

        # setting upmodel
        m = Model(obj)
        #add variable boundary (model , lb, ub)
        addvar!(m, zeros(length(x0)), ones(length(x0)))
        # add constrain
        Nonconvex.add_ineq_constraint!(m, constr)

        options = MMAOptions(; maxiter=200, tol=Tolerance(; kkt=1e-4, f=1e-4))
        TopOpt.setpenalty!(solver, p)
        @time r = Nonconvex.optimize(
            m, MMA87(; dualoptimizer=ConjugateGradient()), x0; options=options
        )

        @show obj(r.minimizer)
        @show constr(r.minimizer)

        # process the vector of areas into JSON and send back to GH
        id = 0:1:(length(x0)-1)
        global outr = Dict(id .=> r.minimizer)
        send(ws, JSON.json(outr))
        open(joinpath(@__DIR__,"\\output\\", "fromGH_24FEB.json"), "w") do f
            write(f, msg)

        #Makie visiiualization
        color_per_cell = [ones(length(x0))/4 2.0*ones(length(x0))/4 3.0*ones(length(x0))/4 4.0*ones(length(x0))/4 ]
        fig = visualize(
            problem, u = solver.u, topology=r.minimizer,
            default_exagg_scale=0.0
            ,default_element_linewidth_scale = 6.0
            ,default_load_scale = 0.1
            ,default_support_scale = 0.1
           # ,cell_color = color_per_cell
           # ,colormap = ColorSchemes.Spectral_10

         )
        Makie.display(fig)
 
    end
end
close(server)
