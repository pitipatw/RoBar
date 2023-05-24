%%

data = readtable('3d2_lines.csv');
x=table2array(data(:,1)) +1;
y=table2array(data(:,2)) +1;

g = graph(x,y) 
pos = table2array(readtable(['3d2_pts.csv']))
plotgraph(g,pos,1,0,[45 45])
[geulertower,dupedgestower,edgesaddedtower,lengthaddedtower,pathtower] = CPP_Algorithm(g,pos);
plotbendpath(geulertower,pathtower,pos,0.01)

savefig(figure1)

