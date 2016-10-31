classdef SourceSegregationHypothesis < Hypothesis
    % class SourceSegregationHypothesis represents a soft mask for the
    % target source

    properties (SetAccess = private)
        mask                % segregation mask for target source
        source = 'target';  % source name
    end

    methods
        function obj = SourceSegregationHypothesis(mask, source)
            obj.mask = mask;
            if nargin > 1
                obj.source = source;
            end
        end
    end

end
% vim: set sw=4 ts=4 et tw=90 cc=+1:
