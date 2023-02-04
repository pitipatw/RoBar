%% Main program for 2022 TopOptProject
close all; clear
% Volume Optimization
% function MAIN_PROGRAM()
% load("ver1.mat","points")
load("ver2_1012.mat" , "points_sym", "nNodes2", "gmodel_2" , "eLength2","tforce2","tpDof2") 
points = points_sym ; 
s_comp = [250 100 50 25 10] ; % 70 50 10] ; 
s_Amin = [0.001 0.005 0.001 0.0001 0.0001] ; 
%Amin = 0.00025 m2
n_s_comp = size(s_comp,2); 
nn = size(points, 1) ; 
s_LC = zeros(nn,3) ;
out_save = [] ;
for K = 1:n_s_comp 
    comp  = s_comp(K) ; 
    Amin = s_Amin(K) ;
    fprintf("Start compliance= %d\n" , comp)  
    tic
    [Aopt, stress_opt, F,d]  = runopt(comp,K,Amin) ;
    toc
    name = get_filename(); 
    name = strcat("Vopt_" , name) ; 
    save(strcat("SAVE_FILES/",name)) ; 


% end
end


%========================================
%========================================
function [Aopt, stress_opt, F,d]  = runopt(comp, K,Amin) 
% Author:  JV Carstensen, CEE, MIT (JK Guest, Civil Eng, JHU)
% Revised: Aug 22 2017, JVC
% Revised: Paul P Wongsittikan, 23 Nov 2022.

% A    = design vairables
% nvar = number of design variables
[force,d,df,stress,eL] = FEM3D(false,false,Amin) ; 
nel = size(stress,2) ; 

LB = 0.00001*ones(nel,1) ; 
UB = Inf*ones(nel,1) ;
% set the stopping criterion and other options you want to select
options = optimset('TolFun',1e-3,'TolCon',1e-3,'GradObj','on',...
    'Hessian','off','GradConstr','on','Display', 'final-detailed');

A0 = 0.1*ones(nel,1) ; 
[Aopt,fopt,exitflag,output] = fmincon(@(A)obj(A,eL),A0,[],[],[],[],LB,UB,...
    @(A)con(A,comp),options);

figure(K) ;hold on ; axis equal
xlim([-5 30]);ylim([-5 30]) ;zlim([-0.5 22])
xlabel('x');ylabel('y');zlabel('z')
view([6 20])

[F,d,df,stress_opt] = FEM3D(Aopt,true,Amin) ;
fprintf("DONE with COMP = %d\n", comp)
end


function[f,df] = obj(A,eL)
f = sum(A.*eL') ;
df = eL' ;
end

function[g,geq,dg,dgeq] = con(A,comp)
geq = [];
dgeq = [];
[force,d,df,~, ~]= FEM3D(A,false,10) ;
fxd_cap = comp;
g   = force'*d-fxd_cap;
dg  = df ;
end

