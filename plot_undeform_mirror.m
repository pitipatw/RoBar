function plot_undeform_mirror(A, nodeCoor,eNodes, nNodes,stress,Amin)
scale = 10 ;
As = A/max(A); 
% Amin = 0.0005; 

info = [A eNodes] ;
[ne ,~] = size(eNodes) ; 

%plot structure
for i = 1:ne
    if abs(A(i)) >= Amin 
    n1 = info(i,2); n2 = info(i,3);
    x1 = nodeCoor(n1,1) ; y1 = nodeCoor(n1,2) ; z1 = nodeCoor(n1,3) ; 
    x2 = nodeCoor(n2,1) ; y2 = nodeCoor(n2,2) ; z2 = nodeCoor(n2,3) ; 
    x = [x1 x2] ;         y = [y1 y2] ;         z = [z1 z2] ; 
    if stress(i) >= 0
        plot3(x,y,z, 'b-o', 'LineWidth', abs(As(i))*scale)
        plot3(27-x,y,z, 'b-o', 'LineWidth', abs(As(i))*scale)
        plot3(27-x,27-y,z, 'b-o', 'LineWidth', abs(As(i))*scale)
        plot3(x,27-y,z, 'b-o', 'LineWidth', abs(As(i))*scale)
    else %edit this back to red 'r'
        plot3(x,y,z, 'r-o', 'LineWidth', abs(As(i))*scale)
        plot3(27-x,y,z, 'r-o', 'LineWidth', abs(As(i))*scale)
        plot3(27-x,27-y,z, 'r-o', 'LineWidth', abs(As(i))*scale)
        plot3(x,27-y,z, 'r-o', 'LineWidth', abs(As(i))*scale)
    end

    end
end
%plot boundaries

