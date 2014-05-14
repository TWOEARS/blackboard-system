classdef ConfusionSolvingKS < AbstractKS
    % ConfusionSolvingKS solves a confusion given new features.
    
    properties (SetAccess = private)
        activeIndex = 0;                    % Index of LocationHypothesis that has just arrived
        confusionHypothesis = [];           % Confusion
        postThreshold = 0.05;               % Posterior probability threshold for a valid LocationHypothesis
    end
    
    methods
        function obj = ConfusionSolvingKS(blackboard)
            obj = obj@AbstractKS(blackboard);
        end
        function setActiveArgument(obj, arg)
            obj.activeIndex = arg;
        end
        function b = canExecute(obj)
            b = false;
            % If no new LocationHypothesis has arrived, do nothing
            if obj.activeIndex < 1
                return
            end
            numConfusions = obj.blackboard.getNumConfusionHypotheses;
            for n=1:numConfusions
                cf = obj.blackboard.confusionHypotheses(n);
                % Fire only if there is an unseen confusion and head has
                % been rotated
                if cf.seenByConfusionSolvingKS == false && cf.headOrientation ~= obj.blackboard.headOrientation
                    obj.confusionHypothesis = cf;
                    b = true;
                    break
                end
            end
        end
        function execute(obj)
            if isempty(obj.confusionHypothesis) || obj.activeIndex < 1
                return
            end
            
            fprintf('-------- ConfusionSolvingKS has fired\n');
            
            headRotation = obj.blackboard.headOrientation - obj.confusionHypothesis.headOrientation;
            predictedLocations = mod(obj.confusionHypothesis.locations - headRotation, 360);
%             numHyp = length(obj.activeIndices);
%             currentLocations = zeros(numHyp, 1);
%             for n=1:numHyp
%                 currentLocations(n) = obj.blackboard.locationHypotheses(obj.activeIndices(n)).location;
%             end
            locHyp = obj.blackboard.locationHypotheses(obj.activeIndex);
            locIdx = locHyp.posteriors > obj.postThreshold;
            newLocations = locHyp.locations(locIdx);
            if ~isempty(newLocations)
                srcLocations = [];
                srcScores = [];
                for n=1:length(predictedLocations)
                    % Check if the predicted location occurs after head 
                    % rotation. If yes, consider it a localised source
                    if sum(predictedLocations(n)==newLocations) > 0
                        srcLocations = [srcLocations obj.confusionHypothesis.locations(n)];
                        srcScores = [srcScores obj.confusionHypothesis.posteriors(n)];
                    end
                end
                % We check if the discarded location is a ghost. If yes, add 
                % its posterior to the score of the localised source
                for n=1:length(predictedLocations)
                    for m = 1:length(srcLocations)
                        if srcLocations(m) == obj.confusionHypothesis.locations(n)
                            continue;
                        end
                        sumLocation = srcLocations(m) + obj.confusionHypothesis.locations(n);
                        if sumLocation == 180 || sumLocation == 540
                            srcScores(m) = srcScores(m) + obj.confusionHypothesis.posteriors(n);
                        end
                    end
                end
                % Record localised sources
                if ~isempty(srcLocations)
                    idx = zeros(length(srcLocations), 1);
                    for n = 1:length(srcLocations)
                        ploc = PerceivedLocation(obj.confusionHypothesis.blockNo, obj.confusionHypothesis.headOrientation, srcLocations(n), srcScores(n));
                        idx(n) = obj.blackboard.addPerceivedLocation(ploc);
                    end
                    notify(obj.blackboard, 'NewPerceivedLocation', BlackboardEventData(idx));
                end
            end
            obj.confusionHypothesis.setSeenByConfusionSolvingKS;
            obj.activeIndex = 0;
            obj.confusionHypothesis = [];
        end
    end
end
