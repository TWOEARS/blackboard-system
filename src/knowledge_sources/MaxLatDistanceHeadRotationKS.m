classdef MaxLatDistanceHeadRotationKS < AbstractKS
    % MaxLatDistanceHeadRotationKS rotate the robot head to maximize
    % lateral distance between potential sources

    %%
    properties (SetAccess = private)
        rotationScheduled = false;    % To avoid repetitive head rotations
        robot;                        % Reference to a robot object
        maxHeadRotateAngle;        
    end

    %%
    methods
        %%
        function obj = MaxLatDistanceHeadRotationKS( robot, maxHeadRotateAngle )
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
            locHypos = obj.blackboard.getLastData( 'locationHypothesis' );
            if isempty( locHypos )
                locHypos = obj.blackboard.getLastData( 'sourcesAzimuthsDistributionHypotheses' );
            end
            assert( numel( locHypos.data ) == 1 );
            locPost = locHypos.data.sourcesDistribution;
            azms = wrapTo180( locHypos.data.azimuths );
            latDists = nan( 1, numel( azms ) );
            longMeans = nan( 1, numel( azms ) );
            for shiftIdx = 0 : numel( azms ) - 1
                shiftedLocPost = circshift( locPost, shiftIdx );
                [latDists(shiftIdx+1),longMeans(shiftIdx+1)] = ...
                    MaxLatDistanceHeadRotationKS.calcLatDist( shiftedLocPost, azms );
            end
            locPost_0azmIdx = find( flip( azms ) == 0 );
            flippedShiftedLocPost = circshift( flip( locPost ), -(locPost_0azmIdx - 1) );
            flippedShiftedLocPost(flippedShiftedLocPost<0.05) = 0;
            fslp_180shifted = circshift( flippedShiftedLocPost, numel( azms ) / 2 );
            % avoid sources at 0° or 180°
            latDists_noTat0 = latDists .* (1 - flippedShiftedLocPost' - fslp_180shifted'); 
            ldlm = round( [latDists_noTat0;longMeans]' * 10000 );
            [~,sortedLatDist_shiftIdx] = sortrows( ldlm, 'descend' );
            maxLatDist_shiftIdx = sortedLatDist_shiftIdx(1);
            headRotateAngle = wrapTo180( azms(1) - azms(maxLatDist_shiftIdx) );
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
       
        %%
        function [latDist,longMean] = calcLatDist( locPost, azms )
            latAzmParts = sin( deg2rad( azms ) );
            longAzmParts = cos( deg2rad( azms ) );
            latDist = 0;
            for ii = 1 : numel( azms ) - 1
                for jj = ii + 1 : numel( azms )
                    latDist_iijj = abs( latAzmParts(ii) - latAzmParts(jj) );
                    locPost_weight = min( locPost(ii), locPost(jj) );
                    latDist = latDist + latDist_iijj * locPost_weight;
                end
            end
            longMean = longAzmParts' * locPost;
%             quantizedLatAzmParts = round( latAzmParts * 300 ) + 301;
%             latLocPost = accumarray( quantizedLatAzmParts, locPost );
%             llpFreq = round( latLocPost * 100 );
%             llpData = repelem( 1:numel( llpFreq ), llpFreq );
%             [normLatLoc_mu,normLatLoc_sigma] = normfit( llpData );
%             latDist = normLatLoc_sigma;
        end
        
    end
%%    
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
