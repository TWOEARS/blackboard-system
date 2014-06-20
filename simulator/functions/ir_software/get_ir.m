function ir = get_ir(irs,phi)
%GET_IR returns a IR for the given apparent angle
%   Usage: ir = get_ir(irs,phi)
%
%   Input parameters:
%       irs     - IR data set
%       phi     - azimuth angle for the desired IR (degree)
%
%   Output parameters:
%       ir      - IR for the given angle (length of IR x 2)
%
%   GET_IR(irs,phi) returns a single IR for the given angle phi.
%   If the desired angle is not present in the IR data set, an 
%   interpolation is applied to create the IR for the desired angle.
%
%   see also: read_irs, ir_intpol
%

% AUTHOR: Sascha Spors, Hagen Wierstorf


%% ===== Checking of input  parameters ==================================
nargmin = 2;
nargmax = 2;
error(nargchk(nargmin,nargmax,nargin))
if ~isnumeric(phi) || ~isscalar(phi)
    error('phi need to be a scalar.');
end


%% ===== Computation ====================================================

phi = phi/180*pi;
% === Check the given angles ===
% Ensure -pi <= phi < pi
phi = correct_azimuth(phi);

% === IR interpolation ===
% Check if the IR dataset contains a measurement for the given angle phi.
% If this is not the case, interpolate the dataset for the given angle.

% Precision of the conformance of the given angle and the desired one
prec = 1000; % which is ca. 0.1 degree
if find(round(prec*irs.apparent_azimuth)==round(prec*phi))
    idx = find(round(prec*irs.apparent_azimuth)==round(prec*phi));
    if length(idx)>1
        error(['%s: the irs data set has more than one entry corresponding to',...
               'an azimuth of %f.'],upper(mfilename),phi);
    end
    ir(:,1) = irs.left(:,idx);
    ir(:,2) = irs.right(:,idx);

else    % Interpolation

    % Find the nearest value smaller than phi
    % Note: this requieres monotonic increasing values of phi in
    % azimuth
    idx1 = find(irs.apparent_azimuth<phi,1,'last');
    if(isempty(idx1))
        % If no value is smaller than phi, use the largest value in
        % azimuth(idx_delta), because of the 0..2pi cicle
        idx1 = length(irs.apparent_azimuth);
    end

    % Find the nearest value larger than phi
    idx2 = find(irs.apparent_azimuth>phi,1,'first');
    if(isempty(idx2))
        % If no value is greater than phi, use the smallest value in
        % azimuth(idx_delta), because of the 0..2pi cicle
        idx2 = 1;
    end

    if idx1==idx2
        error('%s: we have only one apparent_azimuth angle: %f.',...
            upper(mfilename),irs.apparent_azimuth(idx1));
    end

    % Get the single IR corresponding to idx1
    ir1(:,1) = irs.left(:,idx1);
    ir1(:,2) = irs.right(:,idx1);
    % Get the single IR corresponding to idx2
    ir2(:,1) = irs.left(:,idx2);
    ir2(:,2) = irs.right(:,idx2);
    warning('SFS:irs_intpol',...
        ['doing IR interpolation with the angles beta1 = ',...
        '%.1f deg and beta2 = %.1f deg.'],...
        degree(irs.apparent_azimuth(idx1)),...
        degree(irs.apparent_azimuth(idx2)));
    % IR interpolation
    ir = intpol_ir(ir1,irs.apparent_azimuth(idx1),...
        ir2,irs.apparent_azimuth(idx2),phi);

end
