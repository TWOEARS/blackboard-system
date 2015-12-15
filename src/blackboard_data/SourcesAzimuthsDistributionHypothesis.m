classdef SourcesAzimuthsDistributionHypothesis < Hypothesis
    % class SourcesAzimuthsDistributionHypothesis represents a distribution of azimuths
    % for possible source positions

    properties (SetAccess = private)
        posteriors;                        % Posterior distribution for all angles
        locations;                         % Relative locations
        headOrientation;                   % Head orientation angle
        seenByConfusionKS = false;
        seenByConfusionSolvingKS = false;
    end

    methods
        function obj = LocationHypothesis(headOrientation, locations, posteriors)
            obj.headOrientation = headOrientation;
            obj.locations = locations;
            obj.posteriors = posteriors;
        end
        function obj = setSeenByConfusionKS(obj)
            obj.seenByConfusionKS = true;
        end
        function obj = setSeenByConfusionSolvingKS(obj)
            obj.seenByConfusionSolvingKS = true;
        end
    end

end
% vim: set sw=4 ts=4 et tw=90 cc=+1:
