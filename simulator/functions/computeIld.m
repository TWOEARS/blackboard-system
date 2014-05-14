function ild = computeIld(bmR, bmL)
%% COMPUTEILD Computes ILD's between ear signals
%
% Inputs:   bmR - Right ear basilar membrane displacement (NxM Matrix)
%           bmL - Left ear basilar membrane displacement (NxM Matrix)
%           with N: Number of samples per frame, M: Number of bands of
%           gammatone filterbank
%
% Outputs:  ild - Interaural level differences (Mx1 vector)

%% Parameter initialization

% Get signal parameters
frameLength = size(bmR, 1);
numChannels = size(bmR, 2);

% Pre-allocate output signal
ild = zeros(numChannels, 1);

%% Compute ILD's

for k = 1 : numChannels
    % Reset temporary variables
    sumR = 0;
    sumL = 0;
    
    rSig = bmR(:, k);
    lSig = bmL(:, k);
    
    % Perform summation
    for l = 1 : frameLength
        sumR = sumR + rSig(l)^2;
        sumL = sumL + lSig(l)^2;
    end
    
    % Compute ILD for k-th frequency band
    ild(k) = 20 * log10(sumL / sumR);
end