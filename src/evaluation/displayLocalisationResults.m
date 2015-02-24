function displayLocalisationResults(perceivedLocations, sourceAzimuth)
%displayLocalisationResults will print detailed information to the screen
%
%   USAGE:
%       displayLocalisationResults(perceivedLocations, sourceAzimuth)
%
%   INPUT ARGUMENTS:
%       perceivedLocations   - as returned by Blackboard.getData('perceivedLocations')
%       sourceAzimuth        - actual physical position of sound source

fprintf('\n------------------------------------------------------------------------------------\n');
fprintf('Reference target angle: %d degrees\n', sourceAzimuth);
fprintf('------------------------------------------------------------------------------------\n');
fprintf('Localised source angle:\n');
%fprintf('------------------------------------------------------------------------------------\n');
fprintf('BlockTime\tPerceivedLocation\t(head orient., relative loc.)\tProbability\n');
fprintf('------------------------------------------------------------------------------------\n');

estAngles = zeros(length(perceivedLocations),1);

for m=1:length(perceivedLocations)

    relativeLocation = mod( perceivedLocations(m).data.location + ...
        perceivedLocations(m).data.headOrientation, 360 );

    fprintf('% 6.2f\t\t%3.0f degrees\t\t(%3.0f degrees,    %3.0f degrees)\t%.2f\n', ...
        perceivedLocations(m).sndTmIdx, ...
        relativeLocation, ...
        perceivedLocations(m).data.headOrientation, ...
        perceivedLocations(m).data.location, ...
        perceivedLocations(m).data.score);

    estAngles(m) = relativeLocation;
end
fprintf('------------------------------------------------------------------------------------\n');
locError = mean(localisationErrors(sourceAzimuth, estAngles));
fprintf('Mean localisation error: %g\n', locError );
fprintf('------------------------------------------------------------------------------------\n\n');

% vim: set sw=4 ts=4 et tw=90:
