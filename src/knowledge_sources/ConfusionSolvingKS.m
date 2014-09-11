classdef ConfusionSolvingKS < AbstractKS
    % ConfusionSolvingKS solves a confusion given new features.
    
    properties (SetAccess = private)
        activeIndex = 0;                    % Index of LocationHypothesis that has just arrived
        confusionHypothesis = [];           % Confusion
        postThreshold = 0.1;                % Posterior probability threshold for a valid LocationHypothesis
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
            if obj.activeIndex <= 0, return; end;
            confusions = obj.blackboard.getData( 'confusionHypotheses' );
            numConfusions = length( confusions );
            for n=1:numConfusions
                cf = confusions(n).data;
                % Fire only if there is an unseen confusion and head has
                % been rotated
                lastHeadOrientation = obj.blackboard.getLastData( 'headOrientation' ).data;
                if cf.seenByConfusionSolvingKS == false && cf.headOrientation ~= lastHeadOrientation
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
            
            if obj.blackboard.verbosity > 0
                fprintf('-------- ConfusionSolvingKS has fired\n');
            end
            
            lastHeadOrientation = obj.blackboard.getLastData( 'headOrientation' ).data;
            headRotation = lastHeadOrientation - obj.confusionHypothesis.headOrientation;
            % predictedLocations = mod(obj.confusionHypothesis.locations - headRotation, 360);

            newLocHyp = obj.blackboard.getData( 'locationHypotheses', obj.activeIndex ).data;
            idxDelta = int16( headRotation / (newLocHyp.locations(2) - newLocHyp.locations(1)) );
            predictedPosteriors = circshift(newLocHyp.posteriors,[0 idxDelta]);
            % Take the average of the posterior distribution before head
            % rotation and predictd distribution from after head rotation
            post = (obj.confusionHypothesis.posteriors + predictedPosteriors) / 2;
            post = post ./ sum(post);
            
%             hold off;
%             plot(obj.confusionHypothesis.locations, obj.confusionHypothesis.posteriors, 'o--');
%             hold on;
%             plot(obj.confusionHypothesis.locations, predictedPosteriors, 'go--');
%             plot(obj.confusionHypothesis.locations, post, 'ro--');
%             legend('Dist before rotation', 'Dist after rotation', 'Average dist');
            
            [m,idx] = max(post);
            if m > obj.postThreshold;
                % Generate Perceived Location
                ploc = PerceivedLocation(obj.confusionHypothesis.blockNo, ...
                    obj.confusionHypothesis.headOrientation, ...
                    obj.confusionHypothesis.locations(idx), m);
                idx = obj.blackboard.addPerceivedLocation(ploc);
                notify(obj.blackboard, 'NewPerceivedLocation', BlackboardEventData(idx));
            end
            obj.confusionHypothesis.setSeenByConfusionSolvingKS;
            obj.activeIndex = 0;
            obj.confusionHypothesis = [];
        end
    end
end
