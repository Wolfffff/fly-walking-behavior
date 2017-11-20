%Before running this script, load all the variables from single_fly_analysis

%this script will generate a figure with two plots
% The first plot will show the fly's walking trajectory for the selected
% period (A) and the second plot will show curvature/sum etc for the corresponding
% period (type in the number for the varialbe 'A'). This will automatically
% generate fig file.


%%
load('120925video6_ V17 variables_low.mat');
Vertices = horzcat(fly_x,fly_y);
Lines=[(1:(size(Vertices,1)-1))' (2:size(Vertices,1))'];
N=LineNormals2D(Vertices,Lines);
%stopstart=runend;
%stopend=runbeginning;
for i=1:(length(fly_x)); 
%for i=309:315; 
%because normal is a unit vector. The x-component can be used
% to determine the angle it makes with x-axis.
    angle(i)=acos(N(i,1));
% the if loop converts from 0 to pi to -pi to pi
    if N(i,1)>0 && N(i,2)>0
        angle(i)=angle(i);
    elseif N(i,1)>0 && N(i,2)<0
        angle(i)=-angle(i);
    elseif N(i,1)<0 && N(i,2)<0
        angle(i)=-angle(i);       
    elseif N(i,1)<0 && N(i,2)>0
        angle(i)=angle(i);   
    end;
    % get the change in normal (= change in tangent)
    if i==1
    curvature(i) = 0;
    else
    curvature(i) = angle(i)-angle(i-1);
    end
end;
% make stop =0;
curvature=curvature.*(velocity_classified_binary)';
%curvature=curvature./(vel_total)';
[pks,locs]=findpeaks(abs(curvature),'Threshold',3); % taking out really large turns because flies don't do backflip
curvature(locs)=0;

% %for reorientation during stops
angle_before=angle(stop_start);
angle_after=angle(stop_end);
reorientation=angle_after-angle_before;
curvature(stop_end)=reorientation;


A = [1:150]; %type in which frames you want to look at
%find the turns that occurred within 'A'
turn_sh = intersect(frame_turn_sh,A);
turning_frame = intersect(curv_long_mat,A);
segment=curvature(A);
totalturn=cumsum(segment);
figure(2); plot(totalturn);
figure
set(gcf,'position',[100 400 1500 400]);

%walking track
subplot(1,3,1)
plot(in_x,in_y,'k')
hold on
plot(out_x,out_y,'k')

plot(fly_x(A),fly_y(A));
plot(fly_x(A(1)),fly_y(A(1)),'r>'); %start of the track
plot(fly_x(turn_sh),fly_y(turn_sh),'r*'); %mark sharp turns
plot(fly_x(turning_frame),fly_y(turning_frame),'m.'); %mark curving, turning
plot(fly_x(stop_end),fly_y(stop_end),'g.');
plot(fly_x(stop_start),fly_y(stop_start),'g.');
%plot([Vertices(stop_start,1) Vertices(stop_start,1)+5*N(stop_start,1)]',[Vertices(stop_start,2) Vertices(stop_start,2)+5*N(stop_start)]');
%plot([Vertices(stop_end,1) Vertices(stop_end,1)+5*N(stop_end,1)]',[Vertices(stop_end,2) Vertices(stop_end,2)+5*N(stop_end)]');
%plot([Vertices(A,1) Vertices(A,1)+1*N(A,1)]',[Vertices(A,2) Vertices(A,2)+1*N(A,2)]');
title([fig_title ' track from ' num2str(A(1)) 'to ' num2str(A(end))]);

%angle change
subplot(1,3,[2 3])
% plot(A,angle1_run(A)); %angle change in radian
hold on
plot(A,k_run(A),'g') %curvature
plot(A,curvature(A),'r');
% plot(A+5,angle_sum_win(A),'r'); %sum of angle1_run with sliding window of 10 frames
plot(A+5,k_sum_win(A),'b:'); %sum of k_run with sliding window of 10 frames

% l=legend('angle1_run','k_run','angle_sum_win','k_sum_win');
l=legend('k_run','k_sum_win');

set(l,'interpreter','none','box','off');

plot([A(1) A(end)],[0 0],'k:'); % mark 0

%mark sharp  (from curvature)
for i=1:length(turn_sh)
ha = area([turn_sh(i)-1 turn_sh(i)+1],[3 3]); %shade the sharp turn
set(ha,'FaceColor',grey,'EdgeColor','w');
alpha(.3);
end

%mark curving/turning
plot(turning_frame,.7,'mo','markersize',4); %turning/curving after discarding 1 or 2 frame-long turns
plot(stop_end,1,'mo','markersize',8); 
xlim([A(1) A(end)]);
ylim([-5 5]);

set(gcf, 'PaperPositionMode', 'auto');

saveas(gcf,[fig_title ' angle_k' num2str(A(1)) 'to' num2str(A(end)) '.fig']);
figure(3); plot(A,vel_total(A));