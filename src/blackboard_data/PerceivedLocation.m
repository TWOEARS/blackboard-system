classdef PerceivedLocation < Hypothesis
    % class PerceivedLocation represents a perceived source location
    
    properties (SetAccess = private)
        blockNo;                          % Block no
        location;                         % source location
        headOrientation;                  % head orientation
    end
    
    methods
        function obj = PerceivedLocation(blockNo, headOrientation, location, posterior)
            obj.blockNo = blockNo;
            obj.location = location;
            obj.headOrientation = headOrientation;
            obj.setScore(posterior);
        end
    end
    
end
