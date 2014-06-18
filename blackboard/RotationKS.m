classdef RotationKS < AbstractKS
    % RotationKS decides how much to rotate the robot head
    
    properties (SetAccess = private)
        rotationScheduled = false;    % To avoid repetitive head rotations
        activeIndex = 0;              % Index of the new confusion hypothesis
    end
    
    methods
        function obj = RotationKS(blackboard)
            obj = obj@AbstractKS(blackboard);
        end
        function setActiveArgument(obj, arg)
            obj.activeIndex = arg;
        end
        function b = canExecute(obj)
            b = false;
            if obj.activeIndex < 1
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
            % the most likely source location. Negative values mean left 
            % turn
            locHyp = obj.blackboard.confusionHypotheses(obj.activeIndex);
            [~,idx] = max(locHyp.posteriors);
            maxLoc = locHyp.locations(idx);
            if maxLoc <= 180
                headRotateAngle = maxLoc;
            else
                headRotateAngle = maxLoc - 360;
            end
            
            obj.blackboard.adjustHeadOrientation(headRotateAngle);
            
            if obj.blackboard.verbosity > 0
                fprintf('New head orientation is %d degrees\n', obj.blackboard.headOrientation);
            end
            obj.rotationScheduled = false;
            obj.blackboard.setReadyForNextBlock(true);
        end
    end
end
