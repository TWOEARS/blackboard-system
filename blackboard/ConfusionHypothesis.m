classdef ConfusionHypothesis < Hypothesis
    % ConfusedFrame represents a list of locations hypothesised for a frame
    % where there exists a confusion
    
    properties (SetAccess = private)
        blockNo;                           % Block number
        headOrientation;                   % Head orientation angle. Negative values mean left turn
        locations;                         % Hypothesised source location
        posteriors;                        % Posterior for this location     
        seenByConfusionSolvingKS = false;
    end
    
    methods
        function obj = ConfusionHypothesis(blockNo, headOrientation, locations, posteriors)
            obj.blockNo = blockNo;
            obj.headOrientation = headOrientation;
            obj.locations = locations;
            obj.posteriors = posteriors;
        end
        function obj = setSeenByConfusionSolvingKS(obj)
            obj.seenByConfusionSolvingKS = true;
        end
    end
    
end
