 function[unregistered_points, base_points, tform ] = transformgenerator( unregistered, base )

%transformgenerator generates a transformation matrix for two one-frame images already read into matlab as image files. Currently set to local weighted mean (line 48 ) but can be set to any. Called by all registration programs, so needs to stay in this folder. 


 %this is helpful: http://www.mathworks.com/help/toolbox/images/f12-23518.html



 chooser = input ('if selecting points for the first time, press 1. If modifying existing points, press 2'); 
if chooser == 1;

% 
%  CPSELECT(INPUT,BASE) returns control points in CPSTRUCT. INPUT is the
%     image that needs to be warped to bring it into the coordinate system of the
%     BASE image. INPUT and BASE can be either variables that contain grayscale,
%     truecolor, or binary images or strings that identify files containing these
%     same types of images.
% Note   When 'Wait' is set to true, cpselect returns the selected pairs of points, not a handle to the tool:


 [unregistered_points,base_points] = cpselect (unregistered, base, 'Wait', true); %returns a structure of control points

% when you are finished selecting points, just close the control point
% selection tool and wait. 
 
%     CP2TFORM takes pairs of control points and uses them to infer a
%     spatial transformation.     
%     TFORM = CP2TFORM(INPUT_POINTS,BASE_POINTS,TRANSFORMTYPE) returns a TFORM
%     structure containing a spatial transformation. INPUT_POINTS is an M-by-2
%     double matrix containing the X and Y coordinates of control points in
%     the image you want to transform. BASE_POINTS is an M-by-2 double matrix
%     containing the X and Y coordinates of control points in the base
%     image.It  returns a TFORM
%     structure containing a spatial transformation.  TRANSFORMTYPE can be 'nonreflective similarity', 'similarity',
%     'affine', 'projective', 'polynomial', 'piecewise linear' or 'lwm'. 
    
tform = cp2tform(unregistered_points, base_points, 'projective');


%     B = IMTRANSFORM(A,TFORM) transforms the image A according to the 2-D
%     spatial transformation defined by TFORM, which is a tform structure
%     as returned by MAKETFORM or CP2TFORM.

% Another approach is to compute the full extent of the registered image and use the optional imtransform syntax that returns the x- and y-coordinates that indicate the transformed image's position in the intrinsic coordinate system of the base image.


 [registered xdata ydata] = imtransform(unregistered, tform,'FillValues', 255);
%Display the registered image. Overlay a semi-transparent version of the base image for comparison.
clf
figure; imshow(registered, 'XData', xdata, 'YData', ydata)

hold on
h = imshow(base, gray(256));
set(h, 'AlphaData', 0.6)


numpic2 = input('what should the registered image be numbered?');
saveas(h,['registeredimage' num2str(numpic2) '.jpg']);
variables = {'unregistered_points', 'base_points', 'tform'};
uisave(variables)



elseif chooser == 2;
    
 [fileName filePath] = uigetfile('*', 'Select file containing points you wish to modify', '.');
if filePath==0, error('None selected!'); end;
clear base_points;
clear unregistered_points;
load([filePath fileName], 'base_points');
load([filePath fileName], 'unregistered_points');     



[unregistered_points,base_points] = cpselect (unregistered, base, unregistered_points, base_points, 'Wait', true); %returns a structure of control points

tform = cp2tform(unregistered_points, base_points, 'projective');

[registered xdata ydata] = imtransform(unregistered,tform,'FillValues', 255,'XData', [1 size(base,2)],...
        'YData', [1 size(base,1)]);
    
figure; imshow(registered, 'XData', xdata, 'YData', ydata)
hold on
h = imshow(base, gray(256));
set(h, 'AlphaData', 0.6)
numpic3 = input('what should the registered image be numbered?');
saveas(h,['registeredimage' num2str(numpic3) '.jpg']);

% figure(2) 
% imshow(registered, 'XData', xdata, 'YData', ydata)
% numpic = input('what should the registered image be numbered?');
% saveas(h,['registeredimage' num2str(numpic) '.jpg']);

variables = {'unregistered_points', 'base_points', 'tform'};
uisave(variables)

end










% end

