function phi = correct_azimuth(phi)
%CORRECT_AZIMUTH ensures correct values for azimuth angles 
%   Usage: phi = correct_azimuth(phi)
%
%   Input parameters:
%       phi     - azimuth (rad). Can be a single value or a matrix.
%
%   Output paramteres:
%       phi     - angle between -pi and +pi-eps
%
%   CORRECT_AZIMUTH(phi) returns a value for azimuth phi between 
%   -pi and +pi-eps.
%
%   see also: read_irs, get_ir
%

% AUTHOR: Hagen Wierstorf


%% ===== Checking of input  parameters ==================================
nargmin = 1;
nargmax = 1;
error(nargchk(nargmin,nargmax,nargin));
if ~isnumeric(phi) || ~ismatrix(phi)
    error('phi needs to be a matrix.')
end


%% ===== Computation ====================================================

% Ensure -2pi <= phi <= 2pi
phi = rem(phi,2*pi);

% Ensure -pi <= phi < pi
phi(phi<-pi) = phi(phi<-pi) + 2*pi;
phi(phi>=pi) = phi(phi>=pi) - 2*pi;
