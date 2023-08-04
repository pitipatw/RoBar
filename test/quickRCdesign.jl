"""
Quick RC rectangular section design
all units in mm and N, unless otherwise specified.
"""

fc′ = 28.
fy = 420.
cover = 40.
ϵc = 0.003
ϵs_max = 0.005
ϵs_min = 0.002
β1 = clamp(0.85 - 0.05*(fc′ - 28)/7, 0.65, 0.85)

b = 150.0
h = 200.0
stirrup_dia = 12.0

# select a #16 steel
dia = 16.0
as = 200.0

eff_d = h - cover - dia/2
#check steel strain
a = as*fy/(0.85*fc′*b)
c = a/β1
ϵs = (eff_d - c)/c*ϵc
if ϵs < ϵs_min
    println("Too much steel, or too small section")
elseif ϵs > ϵs_max
    println("Good, move one")
end
ϕ = clamp(0.65+0.25*(ϵs - ϵs_min)/(ϵs_max - ϵs_min), 0.65, 0.9)
mu = ϕ*as*fy*(eff_d-a/2)
println("mu = ", mu/1e6, " kN.m")

#simply supported beam
l = 2300.0
pu = 4*mu/l