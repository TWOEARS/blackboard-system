classdef RotationKS < AbstractKS
    % RotationKS decides how much to rotate the robot head
    
    properties (SetAccess = private)
        rotationScheduled = false;    % To avoid repetitive head rotations
        robot;                        % Reference to a robot object
        activeIndex = 0;              % Index of the new confusion hypothesis
    end
    
    methods
        function obj = RotationKS(blackboard, robot)
            obj = obj@AbstractKS(blackboard);
            obj.invocationMaxFrequency_Hz = inf;
            obj.robot = robot;
        end
        function setActiveArgument(obj, arg)
            obj.activeIndex = arg;
        end
        function b = canExecute(obj)
            b = false;
            if obj.activeIndex <= 0
                return
            end
            if obj.rotationScheduled
                b = false;
            else
                b = true;
                obj.rotationScheduled = true;
            end
        end
        function execute(obj)
            if obj.blackboard.verbosity > 0
                fprintf('-------- RotationKS has fired. ');
            end
            
            % Workout the head rotation angle so that the head will face
            % the most likely source location.
            locHyp = obj.blackboard.getData( 'confusionHypotheses', obj.activeIndex ).data;
            [~,idx] = max(locHyp.posteriors);
            maxAngle = locHyp.locations(idx);
            if maxAngle <= 180
                headRotateAngle = maxAngle;
            else
                headRotateAngle = maxAngle - 360;
            end
            
            % Rotate head with a relative angle
            obj.robot.rotateHead(headRotateAngle);
            
            if obj.blackboard.verbosity > 0
                fprintf('Commanded head to rotate about %d degrees\n', headRotateAngle);
            end
            obj.rotationScheduled = false;
        end
    end
end
