using Nonconvex
Nonconvex.@load NLopt

f(x) = sqrt(x[2])
g(x, a, b) = (a*x[1] + b)^3 - x[2]

f(x) = x[1]^2 - 10x[2] -120.
g(x ,a ,b) = a*x[1] + b*x[2] 

model = Model(f)
addvar!(model, [-4., 0.], [5., 10.0])
add_ineq_constraint!(model, x -> g(x, 3, 0))
add_ineq_constraint!(model, x -> g(x, 2, 2))

alg = NLoptAlg(:LD_MMA)
options = NLoptOptions()
r = optimize(model, alg, [0., 0.1], options = options)
r.minimum # objective value
r.minimzer # decision variables