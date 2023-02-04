function name = get_filename()
x = replace(string(datetime) , {':',' ' ,'-'},"_");
% name = replace(strcat("ver1_", string(vf),"_", string(lc), "_", x)     , '.' , 'dot');
name = replace(strcat("ver1_", x) , '.' , 'dot');




