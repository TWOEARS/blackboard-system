classdef ConfusionKS < AbstractKS
    % ConfusionKS examines location hypotheses and decides whether 
    % there is a front-back confusion. In the case of a confusion, a head 
    % rotation will be triggered.
    
    properties (SetAccess = private)
        postThreshold = 0.1;       % Posterior probability threshold for a valid LocationHypothesis
    end

    events
        ConfusedLocations
    end
    
    methods
        function obj = ConfusionKS(blackboard)
            obj = obj@AbstractKS(blackboard);
            obj.invocationMaxFrequency_Hz = inf;
        end
        
        function setPostThreshold(obj, t)
            obj.postThreshold = t;
        end
        
        function b = canExecute(obj)
            b = ~(obj.blackboard.getData( 'locationHypotheses', obj.trigger.tmIdx ).data.seenByConfusionKS);
        end
        
        function execute(obj)
            if obj.blackboard.verbosity > 0
                fprintf('-------- ConfusionKS has fired\n');
            end
            
            locHyp = obj.blackboard.getData( 'locationHypotheses', obj.trigger.tmIdx ).data;
            
            % Generates location hypotheses if posterior > threshold
            locIdx = locHyp.posteriors > obj.postThreshold;
            numLoc = sum(locIdx);
            if numLoc > 1
                % Assume there is a confusion when there are more than 1
                % valid location
                % cf = ConfusionHypothesis(locHyp.blockNo, locHyp.headOrientation, locHyp.locations(locIdx), locHyp.posteriors(locIdx));
                obj.blackboard.addData( 'confusionHypotheses', locHyp, false, obj.trigger.tmIdx );
                notify(obj, 'ConfusedLocations', BlackboardEventData(obj.trigger.tmIdx));
            elseif numLoc == 1
                % No confusion, generate Perceived Location
                ploc = PerceivedLocation(locHyp.headOrientation, locHyp.locations(locIdx), locHyp.posteriors(locIdx));
                obj.blackboard.addData( 'perceivedLocations', ploc, false, obj.trigger.tmIdx );
                notify(obj, 'KsFiredEvent', BlackboardEventData(obj.trigger.tmIdx));
            end
            locHyp.setSeenByConfusionKS;
        end
    end
end
