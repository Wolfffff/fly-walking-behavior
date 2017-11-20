figure
set(gcf,'position',[500 400 640 480]);


for i=1:1000
vid = videoinput('avtmatlabadaptor64_r2009b', 1, 'F0M5_Mono8_640x480');
src = getselectedsource(vid);


Im = getsnapshot(vid);
stop(vid);
delete(vid);


imshow(Im);

hold on

load('130219rimpoints.mat');
plot(inner(:,1),inner(:,2),'--r','linewidth',2);
plot(outer(:,1),outer(:,2),'--b','linewidth',2);
hold off

pause(.01);
end


