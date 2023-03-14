#function (ts::TrussStress{T})(x::PseudoDensities) where {T}
ts = TrussStress(solver)
list_of_areas = 0.2*ones(ncells,1)[:,1]
x= PseudoDensities(list_of_areas)

using UnPack
using Ferrite

println("This is modified")
T = eltype(solver.u)
dim = TopOptProblems.getdim(solver.problem)
dh = solver.problem.ch.dh
N = getncells(dh.grid)
σ = zeros(T, N)
transf_matrices = Matrix{T}[]
maxfevals = 10^8
u_fn = Displacement(solver; maxfevals)
R = zeros(T, (2, 2 * dim))

transf_matrices = Matrix{T}[]
for (cellidx, cell) in enumerate(CellIterator(dh))
    u, v = cell.coords[1], cell.coords[2]
    
    # R ∈ 2 x (2*dim)
    println("=====================================")
    println("new")
    
    R_coord = compute_local_axes(u, v)
    
    fill!(R, 0.0)
    println(transf_matrices)
    R[1, 1:dim] = R_coord[:, 1]
    R[2, (dim + 1):(2 * dim)] = R_coord[:, 2]
    println("This is R")
    println((R))


    println("This is tranf before push")
    println(transf_matrices)
    push!(transf_matrices, copy(R))
    println("This is tranf after push")
    println(transf_matrices)
    println("End loop")
end
###=======================================================
###=======================================================
@unpack σ, u_fn = ts
@unpack global_dofs, solver = u_fn
@unpack penalty, problem, xmin = solver
# p.ch.dh
getdh(p::StiffnessTopOptProblem) = p.ch.dh
dh = getdh(problem)
#ts.fevals = 1
ts.fevals += 1
u = u_fn(x)

getA(sp::TrussProblem) = [cs.A for cs in sp.truss_grid.crosssecs]
As = getA(problem)
@unpack Kes = solver.elementinfo
@unpack fes , fixedload, cells = solver.elementinfo
@show Kes
Kes
@show dh
@show u


for e in 1:length(x)
    # Ke = R' * K_local * R
    # F = R * (R' * K_local * R) * u
    celldofs!(global_dofs, dh, e)
    @show -(transf_matrices[e] * Kes[e] * u.u[global_dofs])[1] / As[e]
    σ[e] = -(transf_matrices[e] * Kes[e] * u.u[global_dofs])[1] / As[e]
end
return copy(σ)
#end

function compute_local_axes(end_vert_u, end_vert_v)
    @assert length(end_vert_u) == length(end_vert_v)
    @assert length(end_vert_u) == 2 || length(end_vert_u) == 3
    xdim = length(end_vert_u)
    L = norm(end_vert_u - end_vert_v)
    @assert L > eps()
    # by convention, the new x axis is along the element's direction
    # directional cosine of the new x axis in the global world frame
    c_x = (end_vert_v[1] - end_vert_u[1]) / L
    c_y = (end_vert_v[2] - end_vert_u[2]) / L
    R = zeros(xdim, xdim)
    if 3 == xdim
        c_z = (end_vert_v[3] - end_vert_u[3]) / L
        if abs(abs(c_z) - 1.0) < eps()
            R[1, 3] = -c_z
            R[2, 2] = 1
            R[3, 1] = c_z
        else
            # local x_axis = element's vector
            new_x = [c_x, c_y, c_z]
            # local y axis = cross product with global z axis
            new_y = -cross(new_x, [0, 0, 1.0])
            new_y /= norm(new_y)
            new_z = cross(new_x, new_y)
            R[:, 1] = new_x
            R[:, 2] = new_y
            R[:, 3] = new_z
        end
    elseif 2 == xdim
        R = [
            c_x -c_y
            c_y c_x
        ]
    end
    return R
end