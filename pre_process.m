%pre-processing
clc
clear
load("ver1.mat", "points")
%%
close all
nNodes1 = size(points, 1) ; 
[gmodel_1 , eLength1] = groundstructure(nNodes1, points ) ;
A1 = ones(size(gmodel_1, 1),1);  
figure(1); hold on ; axis equal ; view(10,25)
pre_plot_undeform(A1,points,gmodel_1,nNodes1,A1)
[tforce1, tpDof1] = applyforce(points, nNodes1) ; 
% save("ver1_1012.mat" , "points", "nNodes1", "gmodel_1" , "eLength1","tforce1","tpDof1") 



%====
%====
%%
con =(points(:,2) <=13.5);
points_sym = points(logical(con),:) ;
nNodes2 = size(points_sym, 1) ; 
[gmodel_2 , eLength2] = groundstructure(nNodes2, points_sym ) ;
A2 = ones(size(gmodel_2, 1),1);  
figure(1); hold on ; axis equal ; view(10,25) ; view(90,0)
pre_plot_undeform(A2,points_sym,gmodel_2,nNodes2,A2)
[tforce2, tpDof2] = applyforce(points_sym, nNodes2) ; 



save("ver3_1212.mat" , "points_sym", "nNodes2", "gmodel_2" , "eLength2","tforce2","tpDof2") 

function [eNodes , eLength] = groundstructure(numberNodes ,nc)
count = 0 ; 
for i = 1:numberNodes
    for j = (i+1):numberNodes
        a = nc(i,:); b = nc(j,:) ;
        xa = a(1) ; ya = a(2) ; za = a(3) ; 
        xb = b(1) ; yb = b(2) ; zb = b(3) ;
        L = norm(a-b,2) ;
        L2D = norm( a(1:2) -b(1:2) ,2 );
        isEdge = a(1) == 0 || a(1) == 27 || a(2) == 0 || a(2) == 27 ;
        isFirst = true ; 
%         isFirst = xa <= 13.5 && xb <= 13.5 && ya <= 13.5 && yb<=13.5 ;
        if ((isEdge && zb == 11.725) || ~isEdge ) && isFirst
%             % L <= 13.5  && (a(3)~=8.2750 ||  b(3) ~= 8.27500)
            count = count +1 ;
            eLength(count) = L ;
            eNodes(count,1) = i ;
            eNodes(count,2) = j ;
        end
    end
end
end



function pre_plot_undeform(A, nodeCoor,eNodes, nNodes,stress)
scale = 1 ;
As = A/max(A); 
Amin = 0.00025; 
info = [A eNodes] ;
[ne ,~] = size(eNodes) ; 

%plot structure
for i = 1:ne
    if abs(A(i)) > Amin 
    n1 = info(i,2); n2 = info(i,3);
    x1 = nodeCoor(n1,1) ; y1 = nodeCoor(n1,2) ; z1 = nodeCoor(n1,3) ; 
    x2 = nodeCoor(n2,1) ; y2 = nodeCoor(n2,2) ; z2 = nodeCoor(n2,3) ; 
    x = [x1 x2] ;         y = [y1 y2] ;         z = [z1 z2] ; 
    if stress(i) >= 0
        plot3(x,y,z, 'b-o', 'LineWidth', abs(As(i))*scale)
    else
        plot3(x,y,z, 'r-o', 'LineWidth', abs(As(i))*scale)
    end
    %plot suppport condition
    if z1 == 8.275 
        plot3(x1,y1,z1, 'gx')
    end
    end
end
%plot boundaries
xlabel('x')
ylabel('y')
zlabel('z')
axis equal
end

function [tforce, tpDof] = applyforce(nodeCoor, nn)
tforce=zeros(nn,3); tpDof = [] ;
tpDof = zeros(12,3) ; % I know this because they are at the base
%tpDof = zeros(10,3) ; % I know this because they are at the base + symmetry
% figure(2)
% hold on
% axis equal
Load_general = 1.2*7511 + 1.6*48069  ; Load_top = 1.2*5010 + 1.6*32045 ;
WL_general   = 0.5*105252            ; WL_top   = 0.5*79289 ;
% WL_general = 0 ; WL_top = 0 ; 
count = 1 ;
for i = 1:nn
    x = nodeCoor(i,1) ; y = nodeCoor(i,2) ; z = nodeCoor(i,3) ;
    switch z
        case 8.2750
            if x == 0 || y == 0||x == 27 || y == 27
                tforce(i,3) = -Load_general;
%                 plot3(x,y,z,'rx')
            end
            if x == 0
                tforce(i,1) = WL_general ;
            end
             tpDof(i,:) = 1 ;
            plot3(x,y,z,'gx')
            count = count +1 ;
            %             plot3(x,y,z,'ro')
        case {11.7250 , 12.8625}
            if (x == 4.5 && y == 13.5) || (x == 22.5 && y == 13.5)
                tpDof(i,2) = 1 ; 
                plot3(x,y,z,'mx')
            end
%             if (x == 13.5 && y == 13.5) || (x == 13.5 && y == 4.5)
%                 tpDof(i,1) = 1 ; 
%                 plot3(x,y,z,'gx')
%             end
            if x == 4.5 || y == 4.5  ||x == 22.5 || y == 22.5
                if z == 11.7250
                    tforce(i,3) = -4/6*Load_general ;
                else
                    tforce(i,3) = -2/6*Load_general ;
                end
                %                 plot3(x,y,z,'mx')
            end
            if x == 4.5
                tforce(i,1) = WL_general ;
            end

        case 14.5875
            if x == 6.75 || y == 6.75  ||x == 20.25 || y == 20.25
                tforce(i,3) = -Load_general;
                %                 plot3(x,y,z,'gx')
            end
            if x == 6.75
                tforce(i,1) = WL_general ;
            end

        case 16.3125
            if x ~= 13.5 && y ~= 13.5
                tforce(i,3) = -Load_general;
                %                 plot3(x,y,z,'bx')
            end
            if x == 13.5
%                 tforce(i,1) = WL_general ;
            end
            if x == 13.5 && y == 13.5 
                tpDof(i,2) = 1 ; 
                plot3(x,y,z,'mx')
            end

        case {18.0375 , 19.7625}
            tforce(i,3) = -Load_top;
            %             plot3(x,y,z,'kx')
            tforce(i,1) = WL_top ;
            if x == 13.5 && y == 13.5 
                tpDof(i,2) = 1 ; 
                plot3(x,y,z,'mx')
            end
           
    end
end
end
