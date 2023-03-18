"""
Plot undeformed of the truss structure
"""
function plot_undeform(A::Array{Float64}, nodeCoor,eNodes, nNodes,stress)
    scale = 1 ;
    As = A/max(A); 
    Amin = 0.00025; 
    Amin = 0.0005;
    info = [A eNodes] ;
    [ne ,~] = size(eNodes) ; 
    
    #plot structure
    for i = 1:ne
        if abs(A(i)) > Amin 
        n1 = info(i,2); n2 = info(i,3);
        x1 = nodeCoor(n1,1) ; y1 = nodeCoor(n1,2) ; z1 = nodeCoor(n1,3) ; 
        x2 = nodeCoor(n2,1) ; y2 = nodeCoor(n2,2) ; z2 = nodeCoor(n2,3) ; 
        x = [x1 x2] ;         y = [y1 y2] ;         z = [z1 z2] ; 
        # if stress(i) >= 0
        #     plot3(x,y,z, 'b-o', 'LineWidth', abs(As(i))*scale)
        # else
        #     plot3(x,y,z, 'b-o', 'LineWidth', abs(As(i))*scale)
        # end
    
        # end
    end
    #plot boundaries
    xlabel('x')
    ylabel('y')
    zlabel('z')
    # axis equal
end
end
