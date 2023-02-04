close all
figure(1) ; hold on ;
text(points(:,1) , points(:,2) , points(:,3) , num2str(tempforce(1,:).'), 'FontSize' , 14)
xlim([0 27]) ;ylim([0 27]) ; zlim([0 27])