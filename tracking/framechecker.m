function [frames_to_correct] = framechecker(start_no, end_no)

%120105 Catherine - Generates a matrix with the frame numbers from all
%videos where the centroid moves more than a fly length (25 pixels, at least on my setup - may need to be optimized for SJ setup if the fly appears smaller) and then launches dltDV5 so that you can correct the tracks.f


currentfolder = pwd;
date = currentfolder(end-5:end);
fname1string = [num2str(date) 'reg'];

frames_to_correct = cell(1,end_no-start_no+1);

%    frames_to_correct = zeros(50,end_no-start_no+1);%an arbitrary number of rows and one column per video

for j = (start_no:end_no); %for each video
    
    fname1fun = [fname1string(1:9) num2str(j) 'bgs_xypts.csv']; %with this name
    
    numvals = csvread(fname1fun,1); %read the centroid positions
    
    for i = 1:length(numvals); %for each frame
        distance = sqrt((diff(numvals(:,1))).^2+ (diff(numvals(:,2))).^2);%calculate the distance the centroid moved from the last frame
    end
    
    
%     frames = find(distance>=25); %if this distance is more than 25 pixels (the fly's approximate length), record the frame number        frames = find(distance>=25); %if this distance is more than 25 pixels (the fly's approximate length), record the frame number
    frames = find(distance>=20); %reducing the distance to make this more sensitive (13/3/18 SJ)
    c = isempty(frames);
    
    if c == 0; % if there were no frames to correct in that video
        frames_to_correct{j}= frames; %otherwise record frames in matrix frames_to_correct - index corrects for not starting with video #1
    end
    
    clear frames
end
% keyboard
display(frames_to_correct);
DLTdv5 %open DLTdv5


