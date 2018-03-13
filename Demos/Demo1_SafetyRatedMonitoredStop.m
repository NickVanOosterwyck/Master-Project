%% Add path
addpath(genpath(pwd)); % make sure current directory is the top map!

%% Clear
clear; close all; clc

%% Connect
rob=ur10core('vrep');    %-- choose UR10
%rob=ur10core('real');
rob.connect();

cam=kinectcore('vrep');  %-- choose kinect
%cam=kinectcore('real');
cam.connect();

%% Set up
%-- move camera
%cam.moveToCameraLocation([2.03 2.03 1.08 90 -45 0]); % north-east

%-- set positions
Home = rob.homeJointTargetPositions;
PickUp = [45 -110 -80 -170 -135 0];
PickUpApp = [45 -113.2953  -44.7716 -201.9331 -135 0];
Place = [-25 -110 -80 -170 -25 0];
PlaceApp = [-25 -113.2953  -44.7716 -201.9331 -25 0];

%-- create path
Path =[Home;PickUpApp;PickUp;PickUpApp;PlaceApp;Place;PlaceApp;Home];

%-- set safety distances
rStop = 3/2;

%% Check pointclouds
cam.getPointCloudCalibration();
cam.getPointCloudComparison();

%% Go home
rob.goHome(0.1);
while ~rob.checkPoseReached(rob.homeJointTargetPositions)
end
disp('Robot is ready in home pose.')

%% Cycle
MaxSpeedFactor = 0.3;
range = 0.5;
iterations = 3;
state = 0;

for it = 1:iterations
    i = 1;
    for i = 1:length(Path)
        state = 1;
        while ~rob.checkPoseReached(Path(i,:),range)
            %tic
            [dist,~] = cam.getClosestPoint();
            %toc
            if dist < rStop
                if state ~=0 && (state ==1 || state ==2)
                rob.stopRobot();
                state = 0; disp('Robot is stopped')
                end
            else
                if  state ~=2 && (state ==0 || state ==1)
                rob.moveToJointTargetPositions(Path(i,:),MaxSpeedFactor);
                state = 2;
                end
            end
        end
    end
end

%% States
% 0	Stop
% 1	Next Target
% 2	Move normal
% 3	Move slow

