"""
A, E, f, g, idb, ien, ndf, nel, nen ,nnp ,nsd ,xn ,sL  = data_truss()

 FEM solver for truss elements
 Author:  JV Carstensen, CEE, MIT (JK Guest, Civil Eng, JHU)
 Revised: Aug 22 2017, JVC
 Revised: Paul P Wongsittikan

"""
function [F,d,df,stress] = FEM_truss()
#  ---- READ IN DATA -----------------------------------------------------
# Get data from data_truss()
A, E, f, g, idb, ien, ndf, nel, nen ,nnp ,nsd ,xn ,sL  = data_truss()

# ---- NUMBER THE EQUATIONS ---------------------------------------------
# line 380
id,neq = number_eq(idb,ndf,nnp);


# ---- FORM THE ELEMENT STIFFNESS MATRICES ------------------------------
# line 324
nee = ndf*nen;                   # number of element equations
Ke  = zeros(nee,nee,nel);
Te  = zeros(nen*1,nen*nsd,nel);  # *1 is specific to truss
for i = 1:nel
    Ke[:,:,i],Te[:,:,i] = Ke_truss(A[i],E[i],ien[:,i],nee,nsd,xn);
end

# ---- PERFORM GLOBAL TO LOCAL MAPPING ----------------------------------
# line 237
LM  = zeros(nee,nel);
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
plot_fac_bar = 1/A(i);
A_min        = 0.01;
plot_truss(A,A_min,f,idr,ien,nel,nnp,nsd,plot_fac_bar,xn);


# =======================================================================

# Sensitivity calculation
df = zeros(nel,1);
de = zeros(4,nel) ; 
for i = 1:nel
    iend = ien(:,i) ;
    Ke0  = zeros(4,4,nel);
    Ke0[:,:,i],Te[:,:,i] = Ke_truss(1,E[i],iend,4,nsd,xn);
    nodes = LM[:,i] ; 
    for k = 1:4 
        if nodes[k] ~= 0
            nd = nodes[k] ; 
            de[k,i] = d[nd] ;
        end
    end
    df[i,1] = -de[:,i]' * Ke0[:,:,i] * de[:,i];
end

return
# =======================================================================