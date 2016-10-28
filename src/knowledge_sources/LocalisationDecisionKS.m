classdef LocalisationDecisionKS < AbstractKS
    % LocalisationDecisionKS examines azimuth hypotheses and decides a
    % source location. In the case of a confusion, a head rotation can be 
    % triggered.

    properties (SetAccess = private)
        postThreshold = 0.1;      % Distribution probability threshold for a valid
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
            
            % If the first block, make a decision based only on the current block
            if obj.prevTimeIdx == 0
                
                post = aziHyp.sourcesDistribution;
                
            elseif obj.prevTimeIdx < obj.trigger.tmIdx
                
                % New SourcesAzimuthsDistributionHypothesis has arrived,
                % integrate with previous Location Hypothesis
                prevHyp = obj.blackboard.getData( ...
                    'locationHypothesis', obj.prevTimeIdx).data;
                headRotation = wrapTo180(aziHyp.headOrientation-prevHyp.headOrientation);
                prevPost = prevHyp.sourcesPosteriors;
                currPost = aziHyp.sourcesDistribution;
                locIdx = currPost > obj.postThreshold;
                if sum(locIdx) > 0
                    if headRotation ~= 0
                        % Only if the new location hypothesis contains strong
                        % directional sources, do the removal
                        [prevPost,currPost] = removeFrontBackConfusion(...
                            prevHyp.sourceAzimuths, prevPost, ...
                            currPost, headRotation);
                        % Changed int16 to round here, which seems to cause problem
                        % with circshift in the next line
                        idxDelta = round(headRotation / ...
                            (aziHyp.azimuths(1) - aziHyp.azimuths(2)));
                        prevPost = circshift(prevPost, idxDelta);
                    end
                else
                    % The new hypothesis doesn't seem to contain strong
                    % directional source. Skip it
                    currPost = 0;
                end
                    
                % Take the average of the sources distribution before head
                % rotation and predictd distribution after head rotation
                post = 0.4 .* currPost + 0.6 .* prevPost;
                post = post ./ sum(post);
            end
            
            % Add Location Hypothesis to Blackboard
            ploc = LocationHypothesis(aziHyp.headOrientation, ...
                    aziHyp.azimuths, post);
            obj.blackboard.addData('locationHypothesis', ploc, false, ...
                obj.trigger.tmIdx);
            obj.prevTimeIdx = obj.trigger.tmIdx;
            aziHyp.seenByLocalisationDecisionKS;
            
            
            
            % Request head rotation to solve front-back confusion
            bRotateHead = false;
            if obj.bSolveConfusion
                % Generates location hypotheses if posterior distribution > threshold
                locIdx = ploc.sourcesPosteriors > obj.postThreshold;
                numLoc = sum(locIdx);
                % Assume a confusion when more than 1 valid location
                if numLoc > 1 || (ploc.relativeAzimuth > 150 && ploc.relativeAzimuth < 210)
                    bRotateHead = true;
                end
            end
            if bRotateHead
                notify(obj, 'RotateHead', BlackboardEventData(obj.trigger.tmIdx));
            else
                notify(obj, 'KsFiredEvent', BlackboardEventData(obj.trigger.tmIdx));
            end
            
        end
        
        % Visualisation
        function visualise(obj)
            if ~isempty(obj.blackboardSystem.locVis)
                ploc = obj.blackboard.getData( ...
                'locationHypothesis', obj.trigger.tmIdx).data;
                obj.blackboardSystem.locVis.setPosteriors(...
                    ploc.sourceAzimuths+ploc.headOrientation, ploc.sourcesPosteriors);
            end
        end
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
