classdef LocalisationDecisionKS < AbstractKS
    % LocalisationDecisionKS examines azimuth hypotheses and decides a
    % source location. In the case of a confusion, a head rotation can be 
    % triggered.

    properties (SetAccess = private)
        postThreshold = 0.05;      % Distribution probability threshold for a valid
                                   % SourcesAzimuthsDistributionHypothesis
        bSolveConfusion = true;    % Invoke ConfusionSolvingKS
        prevTimeIdx = 0;
    end
    
    events
      RotateHead
    end
    
    methods
        function obj = LocalisationDecisionKS(bSolveConfusion)
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
            bExecute = false;
            bWait = false;
            
            aziHyp = obj.blackboard.getData('sourcesAzimuthsDistributionHypotheses', obj.trigger.tmIdx).data;
            if aziHyp.seenByLocalisationDecisionKS
                return;
            end
            
            bExecute = true;
        end

        function execute(obj)
            
            % Get the new azimuth hypothesis
            aziHyp = obj.blackboard.getData( ...
                'sourcesAzimuthsDistributionHypotheses', obj.trigger.tmIdx).data;
            
            % If the first block, simply use the current block
            if obj.prevTimeIdx == 0
                ploc = PerceivedAzimuth(aziHyp.headOrientation, ...
                    aziHyp.azimuths, aziHyp.sourcesDistribution);
                
            elseif obj.prevTimeIdx < obj.trigger.tmIdx
                
                % New SourcesAzimuthsDistributionHypothesis has arrived,
                % integrate with previous Location Hypothesis
                prevHyp = obj.blackboard.getData( ...
                    'locationHypothesis', obj.prevTimeIdx).data;
                headRotation = wrapTo180(prevHyp.headOrientation-aziHyp.headOrientation);
                prevPost = prevHyp.sourcesPosteriors;
                currPost = aziHyp.sourcesDistribution;
                if headRotation ~= 0
                    locIdx = currPost > obj.postThreshold;
                    if sum(locIdx) > 1
                        [currPost, prevPost] = removeFrontBackConfusion(...
                            aziHyp.azimuths, currPost, ...
                            prevPost, headRotation);
                    end
                    % Changed int16 to round here, which seems to cause problem
                    % with circshift in the next line
                    idxDelta = round(headRotation / ...
                        (aziHyp.azimuths(2) - aziHyp.azimuths(1)));
                    prevPost = circshift(prevPost, idxDelta);
                end
                
                % Take the average of the sources distribution before head
                % rotation and predictd distribution after head rotation
                post = 0.5 .* currPost + 0.5 .* prevPost;
                post = post ./ sum(post);
                if min(size(post)) > 1
                    disp(size(post));
                end
                ploc = LocationHypothesis(aziHyp.headOrientation, ...
                    aziHyp.azimuths, post);
            end
                
            % Visualisation
            if ~isempty(obj.blackboardSystem.locVis)
                obj.blackboardSystem.locVis.setPosteriors(...
                    ploc.sourceAzimuths+ploc.headOrientation, ploc.sourcesPosteriors);
            end
            
            % Request head rotation to solve front-back confusion
            bRotateHead = false;
            if obj.bSolveConfusion
                % Generates location hypotheses if posterior distribution > threshold
                locIdx = ploc.sourcesPosteriors > obj.postThreshold;
                numLoc = sum(locIdx);
                % Assume a confusion when more than 1 valid location
                if numLoc > 1
                    bRotateHead = true;
                end
            end
            if bRotateHead
                notify(obj, 'RotateHead', BlackboardEventData(obj.trigger.tmIdx));
            else
                notify(obj, 'KsFiredEvent', BlackboardEventData(obj.trigger.tmIdx));
            end
            
            % Add percieved azimuths to Blackboard
            obj.blackboard.addData('locationHypothesis', ploc, false, ...
                obj.trigger.tmIdx);
            obj.prevTimeIdx = obj.trigger.tmIdx;
            aziHyp.seenByLocalisationDecisionKS;
        end
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
