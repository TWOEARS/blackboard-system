function itd = computeItd(iccMap, fs)
%% COMPUTEITD Computes ITD's between ear signals
%
% Inputs:   iccMap - Interaural cross-correlation matrix (NxM Matrix)
%           fs - Sampling frequency in Hz
%           with N: Number subbands, M: Number of time lags
%
% Outputs:  itd - Interaural time differences (Nx1 vector)

%% Parameter initialization

% Get signal parameters
numChannels = size(iccMap, 1);
numLags = size(iccMap, 2);

% Pre-allocate output signal
itd = zeros(numChannels, 1);

%% Compute ITD's

for k = 1 : numChannels
    [dummy, tauHat] = max(iccMap(k, :));

    delta = interpolateParabolic(iccMap(k, :), tauHat);

    tauHat = tauHat - ((numLags - 1) / 2);
    
    % Compute ITD for k-th subband
    itd(k) = (tauHat + delta) / fs;
end