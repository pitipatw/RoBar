force = tforce2;
pts = points_sym ;
k = size(force,1) ;
f =figure(1) ; hold on ; axis equal
xlim([0 27]) ; ylim([0 27]);
shift = 0.1 ; 
for i = 1:k
    pt = pts(i,:) ;
    x = pts(i,1) ; y = pts(i,2) ; z = pts(i,3); 
    % plot x
    if force(i,1) ~= 0
        text(pt(1)+shift ,pt(2) , pt(3), strcat(num2str(force(i,1)),'N'),'\leftarrow sin(\pi)');
    end
    if force(i,2) ~= 0
        text(pt(1)+shift ,pt(2) , pt(3), strcat(num2str(force(i,2)),'N'))
        text(pt(1) ,pt(2) , pt(3), '\rightarrow','FontSize', 50,'Color', 'blue');
    end
    if force(i,3) ~= 0 
        text(pt(1)+shift ,pt(2) , pt(3), num2str(-force(i,3)))
%         text(pt(1) ,pt(2) , pt(3), '\downarrow','FontSize', 50,'Color', 'red');
        quiver3(x,y,z,force(i,1) ,force(i,2) , force(i,3),0.000025,'r')
    end
end
