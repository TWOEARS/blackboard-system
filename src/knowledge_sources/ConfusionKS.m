classdef ConfusionKS < AbstractKS
    % ConfusionKS examines location hypotheses and decides whether 
    % there is a front-back confusion. In the case of a confusion, a head 
    % rotation will be triggered.
    
    properties (SetAccess = private)
        activeIndex = 0;            % Index of the location hypothesis to be processed
        postThreshold = 0.1;       % Posterior probability threshold for a valid LocationHypothesis
    end
    
    methods
        function obj = ConfusionKS(blackboard)
            obj = obj@AbstractKS(blackboard);
        end
        function setActiveArgument(obj, arg)
            obj.activeIndex = arg;
        end
        function setPostThreshold(obj, t)
            obj.postThreshold = t;
        end
        function b = canExecute(obj)
            b = false;
            if obj.activeIndex < 1
                for n=1:numLocationHypotheses
                    if obj.blackboard.locationHypotheses(n).seenByConfusionKS == false
                        obj.activeIndex = n;
                        b = true;
                        break
                    end
                end
            elseif obj.blackboard.locationHypotheses(obj.activeIndex).seenByConfusionKS == false
                b = true;
            end
        end
        function execute(obj)
            if obj.activeIndex < 1
                return
            end
            
            if obj.blackboard.verbosity > 0
                fprintf('-------- ConfusionKS has fired\n');
            end
            
            locHyp = obj.blackboard.locationHypotheses(obj.activeIndex);
            
            % Generates location hypotheses if posterior > threshold
            locIdx = locHyp.posteriors > obj.postThreshold;
            numLoc = sum(locIdx);
            if numLoc > 1
                % Assume there is a confusion when there are more than 1
                % valid location
                % cf = ConfusionHypothesis(locHyp.blockNo, locHyp.headOrientation, locHyp.locations(locIdx), locHyp.posteriors(locIdx));
                idx = obj.blackboard.addConfusionHypothesis(locHyp);
                notify(obj.blackboard, 'NewConfusionHypothesis', BlackboardEventData(idx));
            elseif numLoc == 1
                % No confusion, generate Perceived Location
                ploc = PerceivedLocation(locHyp.blockNo, locHyp.headOrientation, locHyp.locations(locIdx), locHyp.posteriors(locIdx));
                idx = obj.blackboard.addPerceivedLocation(ploc);
                notify(obj.blackboard, 'NewPerceivedLocation', BlackboardEventData(idx));
                % No confusion, and now it's ready for the next block
                obj.blackboard.setReadyForNextBlock(true);
            end
            locHyp.setSeenByConfusionKS;
            obj.activeIndex = 0;
        end
    end
end
