function icc = computeIcc(bmR, bmL, fs, tau)
%% COMPUTEICC Computes the interaural cross-correlation
%
% Inputs:   bmR - Right ear basilar membrane displacement (NxM Matrix)
%           bmL - Left ear basilar membrane displacement (NxM Matrix)
%           fs  - Sampling frequency in Hz
%           tau - Evaluation time lags in ms
%           with N: Number of samples per frame, M: Number of bands of
%           gammatone filterbank
%
% Outputs:  icc - Interaural level differences (MxT vector)
%           with T: Range of time lags in samples

%% Parameter initialization

% Get signal parameters
frameLength = size(bmR, 1);
numChannels = size(bmR, 2);

% Generate window function
w = hamming(frameLength);

% Transform time lags in samples
lags = round(1E-3 * tau * fs);

% Pre-allocate output signal
icc = zeros(numChannels, 2 * lags + 1);

%% Compute ICC

for k = 1 : numChannels
    % Apply window
    rSig = bmR(:, k) .* w;
    lSig = bmL(:, k) .* w;
    
    % Compute ICC for k-th subband
    icc(k, :) = xcorrNormMEX(lSig, rSig, lags);
end