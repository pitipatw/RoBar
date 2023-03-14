"""
ver 4 FEB 2023
Inputs for truss elements
    Author:  JV Carstensen, CEE, MIT (JK Guest, Civil Eng, JHU)
    Revised: Aug 22 2017, JVC
    Revised: Pitipat P Wongsittikan , 01 FEB 2023
    -----------------------------------------------------------------------
    A(nel,1)        = cross-sectional area of elements
    E(nel,1)        = Young's modulus of elements
    f(ndf,nnp)      = prescribed nodal forces
    g(ndf,nnp)      = prescribed nodal displacements
    idb(ndf,nnp)    = 1 if the degree of freedom is prescribed, 0 otherwise
    ien(nen,nel)    = element connectivities
    ndf             = number of degrees of freedom per node
    nel             = number of elements
    nen             = number of element equations
    nnp             = number of nodes
    nsd             = number of spacial dimensions
    xn(nsd,nnp)     = nodal coordinates
===========================================================================
Outputs
A, E, f, g, idb, ien, ndf, nel, nen ,nnp ,nsd ,xn ,sL  = data_truss()
"""

# function data_truss()
    nsd = 2 ;  # number of spacial dimensions
    ndf = 2 ;  # number of degrees of freedom per node 
    nen = 2 ;  # number of element nodes
    typeof(ndf)
    nnx = 3 ; # number of nodes on X
    nny = 4 ; # number of nodes on Y
    L = 10. ;
    H = 10. ;

    node_points, elements = groundStruct(nnx,nny,L,H) ;
    nnp = length(node_points) # number of nodal points 
    nel = length(elements) # number of elements
    
    @show values(node_points)
    @show collect(node_points)
    xn = transpose(dummy[:,3:4]); 
    xn = node_points
 
    ien = transpose(info) ;
  
    sL = get_length(ien,xn) ; 
    
    E_mat = 29000.;         # Young's modulus [lbf/in²]
    E = E_mat*ones(nel,1);  # Matrix of Young's modulus
    
    # Initial Guess
    A = 10*ones(nel,1) ;
    
    # Support condition: 1 for restrained, 0 for free.
    idb = zeros(Int8,ndf,nnp);
    idb[:,1] .= 1 ;
    idb[2,3] = 1 ;
    
    # There is nothing to do with 'g' at this time. 
    g = zeros(ndf,nnp);
    
    # Nodal Force
    # 1 for x and 2 for y direction. [⇡ +] and [↓ -]
    P = 20e3;     # lbf
    f = zeros(ndf,nnp);

    f[2,2] = -P; # Negative is for downward
    return [A,E,f,g,idb,ien,ndf,nel,nen,nnp,nsd,xn,sL] 
    
# end

# end