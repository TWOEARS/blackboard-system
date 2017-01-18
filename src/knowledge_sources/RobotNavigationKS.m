classdef RobotNavigationKS < AbstractKS
    % RobotNavigationKS
    %
    
    properties (SetAccess = private)
        movingScheduled = false;
        robot
        targetSource = [];
        robotPositions = [
            %95, 97.5; % Outside kitchen
            91, 98; % Kitchen
            91, 102;  % Bed room
            86, 102]; % Living room
    end

    methods
        function obj = RobotNavigationKS(robot, targetSource)

            obj = obj@AbstractKS();
            obj.invocationMaxFrequency_Hz = inf;
            obj.robot = robot;
            
            if exist('targetSource', 'var')
                obj.targetSource = targetSource;
            else
                obj.targetSource = [];
            end
        end

        function setTargetSource(obj, targetSource)
            obj.targetSource = targetSource;
        end

        function [bExecute, bWait] = canExecute(obj)
            bWait = false;
            hyp = obj.blackboard.getLastData('singleBlockObjectHypotheses');
            bExecute = ~isempty(hyp);
        end

        function execute(obj)
            
            if obj.movingScheduled 
                % robot is moving
                [~, statusId] = obj.robot.getNavigationState;
                if statusId == 3
                    % Reached target pos
                    obj.movingScheduled = false;
                else
                    % Still moving
                end
            else
                % Robot is not moving
                % Let us get it to move
                hyp = obj.blackboard.getLastData('singleBlockObjectHypotheses');
 
                idloc = hyp.data;
                bMove = false;
                if ~isempty(obj.targetSource)
                    idx = strcmp({idloc(:).label}, obj.targetSource);
                    if max(idx) > 0 && any(cell2mat({idloc(idx).d}) == 1)
                        bMove = true;
                        idx =  argmax(cell2mat({idloc.p}));
                    end
                end
                if bMove
                    % Now we have identified the target source. We want to
                    % move the robot towards the source

                    % idloc(idx).loc is source location relative to head
                    targetLocBase = idloc(idx).loc + obj.robot.getCurrentHeadOrientation;
                    [posX, posY, theta] = obj.robot.getCurrentRobotPosition;
                    nRobotPositions = size(obj.robotPositions,1);
                    
                    relativeAngles = zeros(nRobotPositions, 1);
                    for idx = 1 : nRobotPositions
                        currentTargetPos = obj.robotPositions(idx, :);
                        relativeAngles(idx) = atan2(posY - currentTargetPos(2), ...
                            posX - currentTargetPos(1)); 
                    end
                    
                    distances = 1 - cos(relativeAngles - targetLocBase);
                    [~, bestPosIdx] = min(distances);
                    
%                     while true
%                         idxLoc = randperm(nRobotPositions,1);
%                         dist = sqrt((posX-obj.robotPositions(idxLoc,1))^2 + (posY-obj.robotPositions(idxLoc,2))^2);
%                         if dist > 1
%                             break;
%                         end
%                     end
                    
                    % Need to work out which angle to move to
                    obj.robot.moveRobot(obj.robotPositions(bestPosIdx,1), obj.robotPositions(bestPosIdx,2), theta, 'absolute');
                     obj.movingScheduled = true;
                else
                    % Not identified the target
                    % Stay put
                end
            end
            notify(obj, 'KsFiredEvent', BlackboardEventData( obj.trigger.tmIdx ));
        end
        
        % Visualisation
        function visualise(obj)

        end
        
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
