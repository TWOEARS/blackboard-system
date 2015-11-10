function D = colorationMooreTan2003(testExcitationPattern, refExcitationPattern)
% This function calculates the values D of the Moore and Tan (2004) model. It uses
% the AFE to calculate the excitation pattern. So, it would also be interesting to
% see if the model has still the same prediction for the original Tan and
% Moore (2003) data.

% FIXME: Moore and Tan (2004) sample the excitation pattern at 0.5 ERB. Wat does this
% mean, how did they implement it?

% Model parameters:
%   * s    - sharpening of the auditory filters
%   * w    - weighting factor between first and second order model parameters
%   * f    - floor value, excitation levels below this level are set to the fixed
%            value f. This value should enhance the prediction for signals were
%            complete parts of the signal are missing.
%   * w_s  - slope of the decrease in weighting for high frequency channels
s = 1.3; % not used yet
w = 0.3;
f = 32; % not used yet
w_s = 0.4;

% First order differences
diffFirstOrder = abs(db(rms(testExcitationPattern))' - ...
    db(rms(refExcitationPattern))');
% Second order differences
for nn = 1:size(diffFirstOrder, 1) - 1
    diffSecondOrder(nn) = ...
        (db(rms(testExcitationPattern(:,nn+1))) - ...
         db(rms(refExcitationPattern(:,nn+1)))) - ...
        (db(rms(testExcitationPattern(:,nn))) - ...
         db(rms(refExcitationPattern(:,nn))));
end
% Create weighting parameter for the different frequency channels
weight = ones(39,1);
weight(18:39) = 1 - w_s .* ((18:39) - 18) / 46;
% Sum and standard deviation of first order differences across frequency channels
sumFirstOrder = sum(abs(weight .* diffFirstOrder));
sdFirstOrder = std(abs(weight .* diffFirstOrder));
% Sum and standard deviation of second order differences across frequency channels
sumSecondOrder = sum(abs(weight(1:end-1) .* diffSecondOrder'));
sdSecondOrder = std(abs(weight(1:end-1) .* diffSecondOrder'));
% Weighted sum of both orders
sumD = w * sumFirstOrder + (1-w) * sumSecondOrder;
sdD = w * sdFirstOrder + (1-w) * sdSecondOrder;
% Use only standard deviaton as metric
D = sdD;
