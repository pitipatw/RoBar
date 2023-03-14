include("Utilities.jl")
include("FEM_utilities.jl")

"""
A, E, f, g, idb, ien, ndf, nel, nen ,nnp ,nsd ,xn ,sL  = data_truss()

 FEM solver for truss elements
 Author:  JV Carstensen, CEE, MIT (JK Guest, Civil Eng, JHU)
 Revised: Aug 22 2017, JVC
 Revised: Paul P Wongsittikan

"""
function FEM_truss()

#  ---- READ IN DATA -----------------------------------------------------
# Get data from data_truss()
# Is there a better way to do this?
A, E, f, g, idb, ien, ndf, nel, nen ,nnp ,nsd ,xn ,sL  = data_truss()
# display(ien)
# ---- NUMBER THE EQUATIONS ---------------------------------------------
# line 380
id::Array{Int8},neq = number_eq(idb,ndf,nnp);

# ---- FORM THE ELEMENT STIFFNESS MATRICES ------------------------------
# line 324
nee::Int8 = ndf*nen;                   # number of element equations
Ke  = zeros(nee,nee,nel);
Te  = zeros(nen*1,nen*nsd,nel);  # *1 is specific to truss
for i = 1:nel
    Ke[:,:,i],Te[:,:,i] = Ke_truss(A[i],E[i],ien[:,i],nee,nsd,xn);
end

# ---- PERFORM GLOBAL TO LOCAL MAPPING ----------------------------------
# line 237
LM  = zeros(Int8,nee,nel);
for i = 1:nel
    LM[:,i] = get_local_id(id,ien[:,i],ndf,nee,nen);
end


# ---- IF THERE IS FREE DEGREES OF FREEDOM, THEN SOLVE THE EQUILIBRIUM --
if (neq > 0)

    # get global force vector (line 275)
    F = globalF(f,g,id,ien,Ke,LM,ndf,nee,nel,nen,neq,nnp);
    
    # solve Kd - F = 0 (line 521)
    d = solveEQ(F,LM,Ke,nee,nel,neq);
end


# ---- POST-PROCESS THE RESULTS -----------------------------------------
# line 419
dcomp,axial,stress,strain,Fe = post_processing(A,d,E,g,id,ien,Ke,ndf,
    nee,nel,nen,nnp,Te);
# dcomp;
# ---- COMPUTE REACTION FORCES ------------------------------------------
# line 482
Rcomp,idr = reactions(idb,ien,Fe,ndf,nee,nel,nen,nnp);
# Rcomp;

# ---- PLOT THE STRUCTURE -----------------------------------------------
# set the plot factor for the thickness of the truss elements
plot_fac_bar = 1;
A_min        = 0.01;
# plot_undeform(A, nodeCoor,eNodes, nNodes,stress)


# Sensitivity calculation
# Define empty sensitivity matrices.
df = zeros(Float64, nel,1) ;
de = zeros(Float64, 4,nel) ; 
for i = 1:nel
    # Initiate Stiffness matrix without YoungModulus. 
    Ke0  = zeros(4,4,nel);
    Ke0[:,:,i],Te[:,:,i] = Ke_truss(1,E[i],ien[:,i],nee,nsd,xn);
    nodes = LM[:,i] ; 
    for k = 1:4 
        if nodes[k] != 0
            nd = nodes[k] ; 
            de[k,i] = d[nd] ;
        end
    end
    df[i,1] = -de[:,i]' * Ke0[:,:,i] * de[:,i];
end
# There could be ρ here that multiply the whole sL.
ρ = 1*ones(Float64, 1, nel)

dg = ρ .* sL

#This part is for two-material truss topology optimization for minimum compliance.
# minimize f = Fᵀd
# subject to 
# K(Ae, xe) = F
# add new a new variable xe. Telling how much material there are,

# basically make the variable longer, i.e. from [A1 A2 A3 ... An] into [A1 A2 A3 ... An x1 x2 x3 ... xn]
# then slice the variable for the input, find sensitivities. then output the objective value. 
#     Etimber = 11.
#     Esteel  = 200.
#     σy_timber = [-8.6 6.6]
#     σ_steel = [-345. 345.]
#     ρtimber = 570.
#     ρsteel = 7870.
#     ECC_timber = 0.42
#     ECC_steel  = 1.45

return [F,d,df,dg,stress]
end
