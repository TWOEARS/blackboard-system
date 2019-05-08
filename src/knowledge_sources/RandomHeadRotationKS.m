classdef RandomHeadRotationKS < AbstractKS
    % MaxLatDistanceHeadRotationKS rotate the robot head to maximize
    % lateral distance between potential sources

    %%
    properties (SetAccess = private)
        rotationScheduled = false;    % To avoid repetitive head rotations
        robot;                        % Reference to a robot object
        maxHeadRotateAngle;
        targetAzm = wrapTo180( randi(72) * 5 );
    end

    %%
    methods
        %%
        function obj = RandomHeadRotationKS( robot, maxHeadRotateAngle )
            obj = obj@AbstractKS();
            obj.invocationMaxFrequency_Hz = inf;
            obj.robot = robot;
            if nargin > 1 && ~isempty( maxHeadRotateAngle )
                obj.maxHeadRotateAngle = maxHeadRotateAngle;
            else
                obj.maxHeadRotateAngle = 20;
            end
            obj.unfocus();
        end

        %%
        function [b, wait] = canExecute(obj)
            b = false;
            wait = false;
            if ~obj.rotationScheduled
                b = true;
                obj.rotationScheduled = true;
            end
        end

        %%
        function execute(obj)
            newRndTargetAzm = wrapTo180( randi(72) * 5 );
            if abs( wrapTo180( newRndTargetAzm - 180 ) ) + abs( wrapTo180( obj.targetAzm - 180 ) ) < 180
                % +-180° is in the acute angle between obj.targetAzm and newRndTargetAzm
                obj.targetAzm = wrapTo180( 0.8 * wrapTo360( obj.targetAzm ) ...
                                         + 0.2 * wrapTo360( newRndTargetAzm ) );
            else
                obj.targetAzm = wrapTo180( 0.8 * obj.targetAzm + 0.2 * newRndTargetAzm );
            end
            obj.targetAzm = round( obj.targetAzm / 5 ) * 5;

            currentHeadOrientation = obj.blackboard.getLastData('headOrientation').data;
            headRotateAngle = wrapTo180( obj.targetAzm - currentHeadOrientation );
            headRotateAngle = min( headRotateAngle, obj.maxHeadRotateAngle );
            headRotateAngle = max( headRotateAngle, -obj.maxHeadRotateAngle );
            
            % Always make sure the head stays in the head turn limits
            [maxLeft, maxRight] = obj.robot.getHeadTurnLimits; 
            newHO = headRotateAngle + obj.robot.getCurrentHeadOrientation;
            if newHO >= maxLeft || newHO <= maxRight
                headRotateAngle = -headRotateAngle;
            end

            % Rotate head with a relative angle
            obj.robot.rotateHead(headRotateAngle, 'relative');

            bbprintf(obj, ['[MaxLatDistanceHeadRotationKS:] Commanded head to rotate about ', ...
                           '%d°. New head orientation: %.0f°\n'], ...
                          headRotateAngle, obj.robot.getCurrentHeadOrientation);
            
            obj.rotationScheduled = false;
        end
        
        %% Visualisation
        function visualise(obj)
            if ~isempty(obj.blackboardSystem.locVis)
                obj.blackboardSystem.locVis.setHeadRotation(...
                    obj.robot.getCurrentHeadOrientation);
            end
        end
        
    end % methods
    
    %%
    methods (Static)
               
    end
%%    
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
