classdef PerceivedLocation < Hypothesis
    % class PerceivedLocation represents a perceived source location
    
    properties (SetAccess = private)
        location;                         % source location
        headOrientation;                  % head orientation
    end
    
    methods
        function obj = PerceivedLocation(headOrientation, location, posterior)
            obj.location = location;
            obj.headOrientation = headOrientation;
            obj.setScore(posterior);
        end
    end
    
end
