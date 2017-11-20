%determines the distance between two points in the same frame - can also be used to generate xy points for ellipse fit to determine eccentricity of the arena.
currentfolder = pwd;
folder_day = currentfolder(end-5:end);
close all
%  load([num2str(day) 'rimpoints.mat']);

filename = [num2str(folder_day) 'video1bgsub_rim.avi'];
offsetvid  = VideoReader(filename);

offsetframe = read(offsetvid,1);
imshow(offsetframe);

  display('choose an ellipse to fit the inner rim first, then double click. Then choose outer rim and double click.');

    h=imellipse;
    inner=wait(h);
%     i=imellipse;
%     slightlybig=wait(i);
%     j=imellipse;
%     slightlysmall=wait(j);
    jj = imellipse;
    outer = wait(jj);
 
%     save([num2str(folder_day) 'rimpoints.mat'], 'inner', 'slightlybig', 'slightlysmall', 'outer'); 
    save([num2str(folder_day) 'rimpoints.mat'], 'inner', 'outer'); 

close all;
% display('draw outer ellipse and double click when finished')
%    h=imellipse;
%     inner=wait(h);
%  
 
%      save([num2str(day) 'rimpoints.mat'], 'inner', 'slightlybig', 'slightlysmall', 'outer'); 

    
%    save([num2str(day) 'rimpoints_extended.mat'], 'inner', 'slightlybig', 'slightlysmall', 'outer'); 
