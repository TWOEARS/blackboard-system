classdef RotationKS < AbstractKS
    % RotationKS decides how much to rotate the robot head
    
    properties (SetAccess = private)
        headRotateAngle;              % Head rotation angle when needed. Negative values mean left turn
        rotationScheduled = false;    % To avoid repetitive head rotations
    end
    
    methods
        function obj = RotationKS(blackboard, headRotateAngle)
            obj = obj@AbstractKS(blackboard);
            obj.headRotateAngle = headRotateAngle;
        end
        function b = canExecute(obj)
            if obj.rotationScheduled
                b = false;
            else
                b = true;
                obj.rotationScheduled = true;
            end
        end
        function execute(obj)
            fprintf('-------- RotationKS has fired. ');
            if obj.blackboard.headOrientation == 0
                obj.blackboard.adjustHeadOrientation(obj.headRotateAngle);
            else
                obj.blackboard.adjustHeadOrientation(-obj.headRotateAngle);
            end
            fprintf('New head orientation is %d degrees\n', obj.blackboard.headOrientation);
            
            obj.rotationScheduled = false;
            obj.blackboard.setReadyForNextBlock(true);
        end
    end
end
