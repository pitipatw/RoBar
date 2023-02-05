"""
P = (xᵉ)^n (P₂-P₁) + P₁
for ρECCᵉ : input P1 = ρ1 ECC1 , P2 = ρ2 ECC2
"""
function SIMP(xᵉ::Float64,P1::Float64,P2::Float64)
# Predefine n = 3
    n = 3
    P = (xᵉ)^n * (P2-P1) + P1

    return P
end

"""
SIMP for ECCe
"""
function 