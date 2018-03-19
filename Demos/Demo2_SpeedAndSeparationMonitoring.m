%% Add path
addpath(genpath(pwd)); % make sure current directory is the top map!

%% Clear
clear; close all; clc

%% Create & Connect
CameraType = 'vrep';    % vrep or real
RobotType = 'vrep';     % vrep or real

cam=kinectcore(CameraType);
rob=ur10core(RobotType);
cam.connect();
rob.connect();

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
rStop = 1;
rSlow = 1.7;

%% Check pointclouds
cam.getPointCloudCalibration();
cam.getPointCloudComparison();

%% Go home
% limit speed
rob.goHome(0.1);
while ~rob.checkPoseReached(rob.homeJointTargetPositions,0.1)
end
disp('Robot is ready in home pose.')

%% Cycle
MaxSpeedFactor = 0.1;
Range = 0.2;
iterations = 1;

state = 0;
lastDist=Inf;
for it = 1:iterations
    i = 1;
    for i = 1:length(Path)
        state=1;
        while ~rob.checkPoseReached(Path(i,:),Range)
            %tic
            [dist,~] = cam.getClosestPoint()
            %toc
            if  dist<rStop
                if state ~=0
                rob.stopRobot(); disp('Robot is stopped')
                state=0;
                end
            elseif dist>rStop && dist<rSlow
                if abs(lastDist-dist)>0.25 || state==1
                    lastDist = dist;
                    Speedfactor = min(((dist-rStop)/(rSlow-rStop))*MaxSpeedFactor,MaxSpeedFactor);
                    rob.moveToJointTargetPositions(Path(i,:),Speedfactor);
                end
                state=3;
            else
                if state ~=2
                    rob.moveToJointTargetPositions(Path(i,:),MaxSpeedFactor);
                state=2;
                end
            end
        end
    end
end
disp('End of loop reached')

%% States
% 0	Stop
% 1	Next Target
% 2	Move normal
% 3	Move slow

