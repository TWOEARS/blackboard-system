classdef RotationKS < AbstractKS
    % RotationKS decides how much to rotate the robot head

    properties (SetAccess = private)
        rotationScheduled = false;    % To avoid repetitive head rotations
        robot;                        % Reference to a robot object
        %rotationAngles = [20 -20]; % left <-- positive angles; negative angles --> right
        minRotationAngle = 15;        % minimum rotation angles
    end

    methods
        function obj = RotationKS(robot)
            obj = obj@AbstractKS();
            obj.invocationMaxFrequency_Hz = inf;
            obj.robot = robot;
            
%             % Compute possible rotation angles
%             % left <-- positive angles; negative angles --> right
%             headOrientation = robot.getCurrentHeadOrientation;
%             %rotationStep = robot.Sources{1}.IRDataset.AzimuthResolution;
%             if isinf(robot.AzimuthMin)
%                 rotationRight = -80;
%             else
%                 rotationRight = round(mod(robot.AzimuthMin-headOrientation, 360) - 360); % right: -78
%             end
%             if isinf(robot.AzimuthMax)
%                 rotationLeft = 80;
%             else
%                 rotationLeft = round(mod(robot.AzimuthMax-headOrientation, 360)); % left: 78
%             end
%             %obj.rotationAngles = rotationRight:rotationStep:rotationLeft;
%             
%             % Force possible rotation angles
%             obj.rotationAngles = obj.rotationAngles(obj.rotationAngles >= rotationRight ...
%                 & obj.rotationAngles <= rotationLeft);
%             
%             % Force a minimum rotation
%             obj.rotationAngles = obj.rotationAngles(obj.rotationAngles >= obj.minRotationAngle ...
%                 | obj.rotationAngles <= -obj.minRotationAngle);
        end

        function setMinimumRotationAngle(obj, angle)
            obj.minRotationAngle = angle;
%             obj.rotationAngles = obj.rotationAngles(obj.rotationAngles >= angle ...
%                 | obj.rotationAngles <= -angle);
%             if isempty(obj.rotationAngles)
%                 error('Please check the minimum rotation as it causes head rotation angles to be empty');
%             end
        end
        
%         function setRotationAngles(obj, angles)
%             obj.rotationAngles = angles;
%             % Force a minimum rotation
%             obj.rotationAngles = obj.rotationAngles(obj.rotationAngles >= obj.minRotationAngle ...
%                 | obj.rotationAngles <= -obj.minRotationAngle);
%         end
        
        function [b, wait] = canExecute(obj)
            b = false;
            wait = false;
            if ~obj.rotationScheduled
                b = true;
                obj.rotationScheduled = true;
            end
        end

        function execute(obj)

            % Get the most likely source direction
            confHyp = obj.blackboard.getData('confusionHypotheses', ...
                obj.trigger.tmIdx).data;
            [~,idx] = max(confHyp.sourcesDistribution);
            % confHyp.azimuths are relative to the current head orientation
            azSrc = wrapTo180(confHyp.azimuths(idx));
            
            % We want to turn the head toward the most likely source
            % direction
            if azSrc > 0
                % Source is at the left side of current head orientation
                headRotateAngle = obj.minRotationAngle;
            else
                % Source is at the right side
                headRotateAngle = -obj.minRotationAngle;
            end
            
            % Always make sure the head stays in the head turn limits
            [maxLeft, maxRight] = obj.robot.getHeadTurnLimits; 
            newHO = headRotateAngle + obj.robot.getCurrentHeadOrientation;
            if newHO >= maxLeft || newHO <= maxRight
                headRotateAngle = -headRotateAngle;
            end

            % Rotate head with a relative angle
            obj.robot.rotateHead(headRotateAngle, 'relative');

            bbprintf(obj, ['[RotationKS:] Commanded head to rotate about ', ...
                           '%d degrees. New head orientation: %.0f degrees\n'], ...
                          headRotateAngle, obj.robot.getCurrentHeadOrientation);
            
            obj.rotationScheduled = false;
            
            % Visualisation
            if ~isempty(obj.blackboardSystem.locVis)
                obj.blackboardSystem.locVis.setHeadRotation(...
                    obj.robot.getCurrentHeadOrientation);
            end
        end
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
