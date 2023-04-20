data = readtable('C:\Users\Piti_\dev\Externally-prestressed-beams\3d1_part1_lines.csv');
x=table2array(data(:,1)) +1;
y=table2array(data(:,2)) +1;
gtower = graph(x,y) 
postower = table2array(readtable(['C:\Users\Piti_\dev\Externally-prestressed-beams\3d1_part1_pts.csv']))
plotgraph(gtower,postower,1,0,[45 45])
[geulertower,dupedgestower,edgesaddedtower,lengthaddedtower,pathtower] = CPP_Algorithm(gtower,postower);
plotbendpath(geulertower,pathtower,postower,0.01)


