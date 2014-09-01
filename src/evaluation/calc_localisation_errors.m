function locErrors = calc_localisation_errors(refAz, estAzs)
%calc_localisation_errors    Calculates localisation errors
%
%USAGE
%  [locErrors] = calc_localisation_errors(refAz, estAzs)
%
%INPUT ARGUMENTS
%    refAz      : source reference azimuth (0 - 359) 
%    estAzs     : a vector containing estimated azimuths (0 - 359)
%
%OUTPUT ARGUMENTS
%    locErrors  : localisation errors. Note the error between 350 and 10 is
%                 20 instead 340 degrees
% 
% Ning Ma, 21 Mar 2014
% n.ma@sheffield.ac.uk
%

locErrors = 180 - abs(abs(estAzs - refAz) - 180);
