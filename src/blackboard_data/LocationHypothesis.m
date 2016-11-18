classdef LocationHypothesis < Hypothesis
    % class LocationHypothesis represents the source location

    properties (SetAccess = private)
        sourcesPosteriors;             % Posterior distribution of source azimuths, relative to head orientation
        sourceAzimuths;                % Relative azimuths corresponding to sourcesPosteriors
        headOrientation;               % Head orientation angle
        
        azimuth;                       % Most likely source azimuth
        relativeAzimuth;               % Most likely source azimuth relative to head orientation
    end

    methods
        function obj = LocationHypothesis(headOrientation, sourceAzimuths, sourcesPosteriors)
            obj.sourceAzimuths = sourceAzimuths;
            obj.sourcesPosteriors = sourcesPosteriors;
            obj.headOrientation = wrapTo360(headOrientation);
            
            [posterior,idx] = max(sourcesPosteriors);
            
            obj.relativeAzimuth = wrapTo360(sourceAzimuths(idx));
            obj.azimuth = wrapTo360(obj.relativeAzimuth + obj.headOrientation);
            obj.setScore(posterior);
        end
    end

end

% vim: set sw=4 ts=4 expandtab textwidth=90 :
