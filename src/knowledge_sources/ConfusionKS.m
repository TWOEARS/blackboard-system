classdef ConfusionKS < AbstractKS
    % ConfusionKS examines azimuth hypotheses and decides whether
    % there is a front-back confusion. In the case of a confusion, a head
    % rotation will be triggered.

    properties (SetAccess = private)
        postThreshold = 0.01;       % Distribution probability threshold for a valid
                                   % SourcesAzimuthsDistributionHypothesis
        bSolveConfusion = true;    % Invoke ConfusionSolvingKS
    end

    methods
        function obj = ConfusionKS(bSolveConfusion)
            obj = obj@AbstractKS();
            obj.invocationMaxFrequency_Hz = inf;
            if nargin > 0
                obj.bSolveConfusion = bSolveConfusion;
            end
        end

        function setPostThreshold(obj, t)
            obj.postThreshold = t;
        end

        function [bExecute, bWait] = canExecute(obj)
            bExecute = ~(obj.blackboard.getData( ...
                'sourcesAzimuthsDistributionHypotheses', ...
                obj.trigger.tmIdx).data.seenByConfusionKS);
            bWait = false;
        end

        function execute(obj)
            aziHyp = obj.blackboard.getData( ...
                'sourcesAzimuthsDistributionHypotheses', obj.trigger.tmIdx).data;
            
            % Generates location hypotheses if posterior distribution > threshold
            locIdx = aziHyp.sourcesDistribution > obj.postThreshold;
            numLoc = sum(locIdx);
            
            if numLoc > 1 && obj.bSolveConfusion
                % Assume a confusion when more than 1 valid location
                obj.blackboard.addData('confusionHypotheses', ...
                    aziHyp, false, obj.trigger.tmIdx);
                notify(obj, 'ConfusedLocations', BlackboardEventData(obj.trigger.tmIdx));
                
            elseif numLoc > 0
                % No confusion, generate Perceived Azimuth
                [maxPost,locIdx] = max(aziHyp.sourcesDistribution);
                
                % Apply exponential interpolation to refine peak position
                delta = interpolateParabolic(aziHyp.sourcesDistribution,locIdx);
                deltaAz = abs(diff(aziHyp.azimuths(1:2)));
                
                ploc = PerceivedAzimuth(aziHyp.headOrientation, ...
                    aziHyp.azimuths(locIdx) + deltaAz*delta, ...
                    maxPost);
                obj.blackboard.addData('perceivedAzimuths', ploc, false, ...
                    obj.trigger.tmIdx);
                notify(obj, 'KsFiredEvent', BlackboardEventData(obj.trigger.tmIdx));
                
                % Visualisation
                if ~isempty(obj.blackboardSystem.locVis)
                    obj.blackboardSystem.locVis.setPosteriors(...
                        aziHyp.azimuths+aziHyp.headOrientation, ...
                        aziHyp.sourcesDistribution);
                end
            end
            
            aziHyp.setSeenByConfusionKS;
        end
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
