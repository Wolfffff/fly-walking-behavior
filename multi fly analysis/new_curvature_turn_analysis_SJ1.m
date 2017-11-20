%Before running this script, load all the variables from single_fly_analysis

%this script will generate a figure with two plots
% The first plot will show the fly's walking trajectory for the selected
% period (A) and the second plot will show curvature/sum etc for the corresponding
% period (type in the number for the varialbe 'A'). This will automatically
% generate fig file.


%%
load('120925video6_ V18 variables');
Vertices = horzcat(fly_x,fly_y);
Lines=[(1:(size(Vertices,1)-1))' (2:size(Vertices,1))'];
N=LineNormals2D(Vertices,Lines);
for i=1:(length(fly_x));
    %because normal is a unit vector. The x-component can be used
    % to determine the angle it makes with x-axis.
    angle(i)=acos(N(i,1));
    % the if loop converts from 0 to pi to -pi to pi
    if N(i,1)>0 && N(i,2)<0
        angle(i)=-angle(i);
    elseif N(i,1)<0 && N(i,2)<0
        angle(i)=-angle(i);
    end;
    
end


% get the change in normal (= change in tangent)
%SJ: for angle changes from NW quadrant to SW quadrant, (i.e. .9*pi to
%-.9*pi change is likely to be .2*pi change, rather than 1.8*pi change)
curvature = diff(angle);
curvature = [0 curvature];
for i=2:length(angle)
    if angle(i-1)> 3*pi/4 && angle(i) < -3*pi/4 %NW to SW
        curvature(i) = 2*pi + angle(i) - angle(i-1);
    elseif angle(i-1) < -3*pi/4 && angle(i) > 3*pi/4 %SW to NW
        curvature(i) = angle(i) -angle(i-1) - 2*pi;
    end
end

% make stop =0; Here the run threshold is higher to get rid of erroneous
%turn when 
new_velocity_classified_binary=velocity_classified_binary;
for i=1:length(velocity_classified_binary)
 if (vel_total(i)<0.2)
 new_velocity_classified_binary(i)=0;
 end
end
curvature=curvature.*(new_velocity_classified_binary)';
%curvature=curvature./(vel_total)';
%% redefining run stop for curvature. This recalculates stop beginning and end. Basically
% all stops are stops + if velocity drops below 0.2 is also a stop + if
% stop is less than 5 frames it is not counted for reorientation
% calculation
rs_trans=diff(new_velocity_classified_binary);
run_start=find(rs_trans==1);
stop_end=run_start-1;
stop_start=find(rs_trans==-1);
run_end=stop_start-1;

if new_velocity_classified_binary(1) == 0
    stop_start=cat(1,1,stop_start);
end

if new_velocity_classified_binary(end)==0
    stop_end=cat(1,stop_end, length(new_velocity_classified_binary));
end
abc=stop_start;
def=stop_end;
size(stop_start)
size(stop_end)
j=0;
for i=1:(length(abc)) 
    if((def(i)-abc(i))<5);
         stop_start(i-j)=[];stop_end(i-j)=[];
         j=j+1;
    end
end
size(stop_start)
size(stop_end)
angle_before=angle(stop_start);
angle_after=angle(stop_end);

reorientation=angle_after-angle_before;
%correcting for pi to -pi conversion 
for i=1:length(angle_before)
    if angle_before(i)> 3*pi/4 && angle_after(i) < -3*pi/4 %NW to SW
        reorientation(i) = 2*pi + angle_after(i) - angle_before(i);
    elseif angle_before(i) < -3*pi/4 && angle_after(i) > 3*pi/4 %SW to NW
        reorientation(i) = angle_after(i) - angle_before(i) - 2*pi;
    end
end
curvature(stop_end)=reorientation;

% sum of  curvature with sliding windows===================================
% window size = 5;
curvature_sum = zeros(1,length(curvature));%pre-allocate an array to save sum of curvature from sliding windows

for p = 1:length(curvature)
    if p < 3 %first 2 frames
        curvature_sum(p) = nansum(curvature(1:p));
    elseif p > (length(curvature) -2) %last 2 frames
        curvature_sum(p) = nansum(curvature(p:end));
    else
        curvature_sum(p) = nansum(curvature(p-2:p+2));
    end
end


% sharp turns and curved walks

%sharp turns
curv_th_s_CV = .7;
[~,frame_turn_sh_CV] = findpeaks(abs(curvature),'MINPEAKHEIGHT',curv_th_s_CV,'MINPEAKDISTANCE',8);

%sharp turns using curvature_sum
curv_th_s_CV2 = 1.3;
[~,frame_turn_sh_CV_sum] = findpeaks(abs(curvature_sum),'MINPEAKHEIGHT',curv_th_s_CV2,'MINPEAKDISTANCE',8);

%if the velocity after the sharp turn is below the run threshold, ignore
%them (6 continous frame)
vel_check = frame_turn_sh_CV_sum;
x=0;
for p=1:length(vel_check)
    if vel_check(p)+5 <= length(curvature);
        if sum(velocity_classified(vel_check(p):(vel_check(p)+5)) < runthreshold) == 6 %they are all below runthreshold
            x=x+1; not_run(x) = vel_check(p);
        end
    end
end


%find 1-frame long peaks (probably artifical jerks, not sharp turns)
[~,oneframe_peaks] = findpeaks(abs(curvature),'MINPEAKHEIGHT',curv_th_s_CV,'THRESHOLD',.7,'MINPEAKDISTANCE',10);


%curved turns
%==turning/curved walking analysis without using 'findpeaks'===============
turn_th_CV = 0.3; %set the threshold to define 'curving/turning' for sliding window-sum

cv_frame_pos_CV = find(curvature_sum > turn_th_CV); %get the frame #: +
cv_frame_neg_CV = find(curvature_sum < -turn_th_CV);

% 1. if there is one frame between two turns, label that frame as also a
% turn
% 2. if one turning is less than 3 frame-long, discard those turns

%if there is a period where only one frame is missing from the turn, also
%label them as turn
temp = cv_frame_pos_CV(find(diff(cv_frame_pos_CV) == 2));
frame_bw_turn_pos = temp+1;
temp = cv_frame_neg_CV(find(diff(cv_frame_neg_CV) == 2));
frame_bw_turn_neg = temp+1;

%make a new array to save frame # from both cv_frame_ and frame_bw_turn_
temp = horzcat(cv_frame_pos_CV,frame_bw_turn_pos);
cv_frame_pos_CV1 = sort(temp);
temp = horzcat(cv_frame_neg_CV,frame_bw_turn_neg);
cv_frame_neg_CV1 = sort(temp);

%+ and - together
cv_frame_CV = horzcat(cv_frame_pos_CV1,cv_frame_neg_CV1);
cv_frame_CV = sort(cv_frame_CV); %this is the variable used for quantification

%sort out individual curved walks
temp = diff(cv_frame_CV);
discontinuous = (find(temp ~= 1));%discontinous points; in between consecutive curving/turning (end of one turn)

starts = [cv_frame_CV(1) cv_frame_CV(discontinuous+1)]; %start of each turn
ends = [cv_frame_CV(discontinuous) cv_frame_CV(end)]; %end of each turn

each_curv_CV = cell(length(starts),1);
for i=1:length(starts)
    each_curv_CV{i} =(starts(i):ends(i))'; %this cell array contains all the curved walks, each as a cell
end

%get rid of 1-frame or 2 frame long curving/turning
% to exclude other (e.g. 3 frame-long, or 4 frame-long), just add more
% lines such as threeframeturn = find(curv_length ==3) etc...
curv_length = cellfun(@length,each_curv_CV);
oneframeturn = find(curv_length == 1); %which cell's length is one?
twoframeturn = find(curv_length ==2); %2 frame turn?
onetwo_turn = [oneframeturn; twoframeturn];
onetwo_turn = sort(onetwo_turn);%oneframeturn + twoframeturn

long_turn = [1:length(each_curv_CV)];
long_turn = setdiff(long_turn,onetwo_turn); %find turns that are not one or two frames-long
long_turn = long_turn'; %index for 3 or longer frame/turn
curv_long_CV = each_curv_CV(long_turn); %get turnings that are longer than 3 frames

%convert from cell array to matrix
curv_long_mat_CV = cell2mat(curv_long_CV);%this array contains all the frame # for curved walks


%% old curvature calculation
k = LineCurvature2D(Vertices);
k= k(1:end-1);%remove the last point
k=[k;0]; %add 0 for the last point

k_run=k.*(velocity_classified_binary); %changes all the curvature data during stops to 0

% sum of  curvature with sliding windows===================================
% window size = 5;
k_sum_win = zeros(1,length(k_run));%pre-allocate an array to save sum of curvature from sliding windows

for p = 1:length(k_run)
    if p < 3
        k_sum_win(p) = nansum(k_run(1:p));
    elseif p > (length(k_run) -2)
        k_sum_win(p) = nansum(k_run(p:end));
    else
        k_sum_win(p) = nansum(k_run(p-2:p+2));
    end
end


% sharp turns and curved walks

%cur%sharp turns
curv_th_s = 1;
[peaks,frame_turn_sh] = findpeaks(abs(k_run),'MINPEAKHEIGHT',curv_th_s,'MINPEAKDISTANCE',10);



%==turning/curved walking analysis without using 'findpeaks'===============
turn_th = 0.2; %set the threshold to define 'curving/turning' for sliding window-sum

cv_frame_pos = find(k_sum_win > turn_th); %get the frame #: +
cv_frame_neg = find(k_sum_win < -turn_th);

% 1. if there is one frame between two turns, label that frame as also a
% turn
% 2. if one turning is less than 3 frame-long, discard those turns

%if there is a period where only one frame is missing from the turn, also
%label them as turn
temp = cv_frame_pos(find(diff(cv_frame_pos) == 2));
frame_bw_turn_pos = temp+1;
temp = cv_frame_neg(find(diff(cv_frame_neg) == 2));
frame_bw_turn_neg = temp+1;

%make a new array to save frame # from both cv_frame_ and frame_bw_turn_
temp = horzcat(cv_frame_pos,frame_bw_turn_pos);
cv_frame_pos1 = sort(temp);
temp = horzcat(cv_frame_neg,frame_bw_turn_neg);
cv_frame_neg1 = sort(temp);

%+ and - together
cv_frame = horzcat(cv_frame_pos1,cv_frame_neg1);
cv_frame = sort(cv_frame); %this is the variable used for quantification

%sort out individual curved walks
temp = diff(cv_frame);
discontinuous = (find(temp ~= 1));%discontinous points; in between consecutive curving/turning (end of one turn)

starts = [cv_frame(1) cv_frame(discontinuous+1)]; %start of each turn
ends = [cv_frame(discontinuous) cv_frame(end)]; %end of each turn

each_curv = cell(length(starts),1);
for i=1:length(starts)
    each_curv{i} =(starts(i):ends(i))'; %this cell array contains all the curved walks, each as a cell
end

%get rid of 1-frame or 2 frame long curving/turning
% to exclude other (e.g. 3 frame-long, or 4 frame-long), just add more
% lines such as threeframeturn = find(curv_length ==3) etc...
curv_length = cellfun(@length,each_curv);
oneframeturn = find(curv_length == 1); %which cell's length is one?
twoframeturn = find(curv_length ==2); %2 frame turn?
onetwo_turn = [oneframeturn; twoframeturn];
onetwo_turn = sort(onetwo_turn);%oneframeturn + twoframeturn

long_turn = [1:length(each_curv)];
long_turn = setdiff(long_turn,onetwo_turn); %find turns that are not one or two frames-long
long_turn = long_turn'; %index for 3 or longer frame/turn
curv_long = each_curv(long_turn); %get turnings that are longer than 3 frames

%convert from cell array to matrix
curv_long_mat = cell2mat(curv_long);%this array contains all the frame # for curved walks


%%
A = [1229:1241]; %type in which frames you want to look at
%find the turns that occurred within 'A'
turn_sh = intersect(frame_turn_sh,A);
turning_frame = intersect(curv_long_mat,A);
segment=curvature(A);
%new curvature
turn_sh_CV = intersect(frame_turn_sh_CV,A);
turning_frame_CV = intersect(curv_long_mat_CV,A);
%one frame peaks
turn_oneframe = intersect(oneframe_peaks,A);
%sharp turns with curvature_sum
turn_sh_CV_sum = intersect(frame_turn_sh_CV_sum,A);


totalturn=cumsum(segment);
figure(2); plot(totalturn);

figure
set(gcf,'position',[100 20 1500 800]);

%walking track
subplot(2,3,1)
plot(in_x,in_y,'k')
hold on
plot(out_x,out_y,'k')

plot(fly_x(A),fly_y(A),'.-');
plot(fly_x(A(1)),fly_y(A(1)),'r>'); %start of the track
plot(fly_x(turning_frame),fly_y(turning_frame),'m.'); %mark curving, turning
plot(fly_x(turn_sh),fly_y(turn_sh),'r*'); %mark sharp turns

plot(fly_x(stop_end),fly_y(stop_end),'ko');
plot(fly_x(stop_start),fly_y(stop_start),'ks');
%plot([Vertices(stop_start,1) Vertices(stop_start,1)+5*N(stop_start,1)]',[Vertices(stop_start,2) Vertices(stop_start,2)+5*N(stop_start)]');
%plot([Vertices(stop_end,1) Vertices(stop_end,1)+5*N(stop_end,1)]',[Vertices(stop_end,2) Vertices(stop_end,2)+5*N(stop_end)]');
%plot([Vertices(A,1) Vertices(A,1)+1*N(A,1)]',[Vertices(A,2) Vertices(A,2)+1*N(A,2)]');
title([fig_title ' track from ' num2str(A(1)) 'to ' num2str(A(end))]);

%angle change
subplot(2,3,[2 3])
% plot(A,angle1_run(A)); %angle change in radian
hold on
plot(A,k_run(A),'g') %curvature
% plot(A,curvature(A),'r');
plot(A,k_sum_win(A),'b--'); %sum of k_run with sliding window of 10 frames
% plot(A,curvature_sum(A),'r--');

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
%mark the end of stop
plot(stop_end,1,'ko','markersize',8);
plot(stop_start,1,'ks','markersize',8);


xlim([A(1) A(end)]);
ylim([-pi pi]);

% new curvature
%walking track
subplot(2,3,4)
plot(in_x,in_y,'k')
hold on
plot(out_x,out_y,'k')

plot(fly_x(A),fly_y(A),'.-');
plot(fly_x(A(1)),fly_y(A(1)),'r>'); %start of the track
plot(fly_x(turn_sh_CV_sum),fly_y(turn_sh_CV_sum),'r*'); %mark sharp turns
plot(fly_x(not_run),fly_y(not_run),'kX'); %mark sharp turns that are not real runs

plot(fly_x(turning_frame_CV),fly_y(turning_frame_CV),'g.'); %mark curving, turning
plot(fly_x(stop_end),fly_y(stop_end),'ko');
plot(fly_x(stop_start),fly_y(stop_start),'ks');
title([fig_title ' track from ' num2str(A(1)) 'to ' num2str(A(end))]);

subplot(2,3,[5 6])
% plot(A,angle1_run(A)); %angle change in radian
hold on
plot(A,curvature(A),'g');
plot(A,curvature_sum(A),'b--');

l=legend('curvature(Normal)','curvature_sum');

set(l,'interpreter','none','box','off');

plot([A(1) A(end)],[0 0],'k:'); % mark 0

%mark sharp  (from curvature)
% if isempty(turn_sh_CV) ==0
% plot(turn_sh_CV,1.5,'r*','markersize',10); %turning/curving after discarding 1 or 2 frame-long turns
% end
% 
% if isempty(turn_oneframe) == 0
% plot(turn_oneframe,1.6,'ro','markersize',10);
% end

%sharp turns from curvature_sum
if isempty(turn_sh_CV_sum) == 0
    plot(turn_sh_CV_sum,1.7,'r>','markersize',10);
end

%sharp turns that are really slow
plot(not_run,2,'kX','markersize',10);

%mark curving/turning
plot(turning_frame_CV,.7,'mo','markersize',4); %turning/curving after discarding 1 or 2 frame-long turns
%mark the end of stop
plot(stop_end,1,'ko','markersize',8);
plot(stop_start,1,'ks','markersize',8);

xlim([A(1) A(end)]);
ylim([-pi pi]);

title(['sharp turn threshold = ' num2str(curv_th_s_CV2) ', curv threshold = ' num2str(turn_th_CV)]);

set(gcf, 'PaperPositionMode', 'auto');

saveas(gcf,[fig_title ' angle_k' num2str(A(1)) 'to' num2str(A(end)) '.fig']);

%%
figure(3); 
plot(A,vel_total(A),'.-');
hold on
plot([A(1) A(end)],[stopthreshold stopthreshold],'g');
plot([A(1) A(end)],[runthreshold runthreshold],'g');
plot(A,new_velocity_classified_binary(A),'r')
plot(A,velocity_classified_binary(A),'g')