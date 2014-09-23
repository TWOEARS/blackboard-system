classdef ConfusionKS < AbstractKS
    % ConfusionKS examines location hypotheses and decides whether 
    % there is a front-back confusion. In the case of a confusion, a head 
    % rotation will be triggered.
    
    properties (SetAccess = private)
        activeIndex = 0;            % Index of the location hypothesis to be processed
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
        function setActiveArgument(obj, arg)
            obj.activeIndex = arg;
        end
        function setPostThreshold(obj, t)
            obj.postThreshold = t;
        end
        
        function b = canExecute(obj)
            b = ~(obj.blackboard.getData( 'locationHypotheses', obj.activeIndex ).data.seenByConfusionKS);
        end
        
        function execute(obj)
            if obj.blackboard.verbosity > 0
                fprintf('-------- ConfusionKS has fired\n');
            end
            
            locHyp = obj.blackboard.getData( 'locationHypotheses', obj.activeIndex ).data;
            
            % Generates location hypotheses if posterior > threshold
            locIdx = locHyp.posteriors > obj.postThreshold;
            numLoc = sum(locIdx);
            if numLoc > 1
                % Assume there is a confusion when there are more than 1
                % valid location
                % cf = ConfusionHypothesis(locHyp.blockNo, locHyp.headOrientation, locHyp.locations(locIdx), locHyp.posteriors(locIdx));
                obj.blackboard.addData( 'confusionHypotheses', locHyp );
                notify(obj, 'ConfusedLocations');
            elseif numLoc == 1
                % No confusion, generate Perceived Location
                ploc = PerceivedLocation(locHyp.headOrientation, locHyp.locations(locIdx), locHyp.posteriors(locIdx));
                obj.blackboard.addData( 'perceivedLocations', ploc );
                notify(obj, 'KsFiredEvent');
            end
            locHyp.setSeenByConfusionKS;
            obj.activeIndex = 0;
        end
    end
end
