using HTTP.WebSockets
using JSON
using TopOpt, LinearAlgebra, StatsFuns
using Makie, GLMakie
using TopOpt.TrussTopOptProblems.TrussVisualization: visualize
using StaticArrays



server = WebSockets.listen!("127.0.0.1", 2000) do ws
    for msg in ws
        println("HI")
        open(joinpath(@__DIR__, "fromGH1.json"), "w") do f
            write(f, msg)
        end
        data = JSON.parse(msg)
        node_points, elements, mats, crosssecs, fixities, load_cases = load_truss_json(joinpath(@__DIR__, "fromGH1.json"))

        ndim, nnodes, ncells = length(node_points[1]), length(node_points), length(elements)
        loads = load_cases["0"]
        problem = TrussProblem(
            Val{:Linear}, node_points, elements, loads, fixities, mats, crosssecs
        )
        println("Inputs Pass Successfully!")
        xmin = 0.0001 # minimum density
        x0 = fill(1.0, ncells) # initial design
        p = 4.0 # penalty
        # V = 0.1 # maximum volume fraction
        V = data["maxVf"]

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

        options = MMAOptions(; maxiter=1000, tol=Tolerance(; kkt=1e-4, f=1e-4))
        TopOpt.setpenalty!(solver, p)
        @time r = Nonconvex.optimize(
            m, MMA87(; dualoptimizer=ConjugateGradient()), x0; options=options
        )

        @show obj(r.minimizer)
        @show constr(r.minimizer)
        fig = visualize(
            problem, solver.u, topology=r.minimizer,
            default_exagg_scale=0.0 #,default_element_linewidth_scale = 3.0
        )
        Makie.display(fig)

        send(ws, "Im back!")
    end

end
close(server)

