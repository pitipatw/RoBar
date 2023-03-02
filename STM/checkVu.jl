"""
23.4.4
"""
function checkVu(Vu ::Float64,ϕ::Float64, θ::Float64, λ::Float64, fc′::Float64, bw::Float64, d::Float64)
    λs = clamp( sqrt( 2 / (0.004*d)) ,0,1)
    check =  Vu <= (0.42*ϕ*tan(θ)*λ*λs*sqrt(fc′)*bw*d)
    return check
end
"""