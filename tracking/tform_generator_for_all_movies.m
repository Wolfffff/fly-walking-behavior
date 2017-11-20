%this script generates a transformation matrix that can be applied to any subsequent movie, so long as the cameras are in exactly the same position. 

 %this is helpful to understand the functions called by transformgenerator:
 %http://www.mathworks.com/help/toolbox/images/f12-23518.html
clear all;
close all;

 unregistered = uigetfile('*', 'Select the image file you would like to register', '.'); 
  unreg = unregistered;
   unreg = VideoReader(unregistered);

 base = uigetfile('*', 'Select the reference image you are registering to', '.');
 base = VideoReader(base);

      base = read(base, 1); %read only the first frame
      unregistered = read(unreg,1);
%  unregistered = imread(unreg);
[unregistered_points, base_points, tform ] = transformgenerator( unregistered, base );



