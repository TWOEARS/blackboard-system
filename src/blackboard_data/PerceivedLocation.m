classdef PerceivedLocation < Hypothesis
    % class PerceivedLocation represents a perceived source location

    properties (SetAccess = private)
        location;                         % source location
        headOrientation;                  % head orientation
        relativeLocation;                 % source location relative to head orientation
    end

    methods
        function obj = PerceivedLocation(headOrientation, location, posterior)
            obj.location = wrapTo360(location);
            obj.headOrientation = wrapTo360(headOrientation);
            obj.relativeLocation = wrapTo360(obj.location + obj.headOrientation);
            obj.setScore(posterior);
        end
    end

end

% vim: set sw=4 ts=4 expandtab textwidth=90 :
