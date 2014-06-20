function [CUE,SET] = calcILD(SIGNAL,CUE)
%calcILD   Calculate interaural level differences (ILDs). 
%   Negative ILDs are associated with sound sources positioned at the
%   left-hand side and positive ILDs with sources at the right-hand side.  
%
%USAGE
%   [CUE,SET] = calcILD(SIGNAL,CUE)
%
%INPUT ARGUMENTS
%      SIGNAL : signal structure
%         CUE : cue structure initialized by init_WP2
% 
%OUTPUT ARGUMENTS
%         CUE : updated cue structure
%         SET : updated cue settings (e.g., filter states)

%   Developed with Matlab 8.2.0.701 (R2013b). Please send bug reports to:
%   
%   Authors :  Tobias May � 2014
%              Technical University of Denmark
%              tobmay@elektro.dtu.dk
% 
%   History :  
%   v.0.1   2014/02/22
%   ***********************************************************************


%% GET INPUT DATA
% 
% 
% Input signal and sampling frequency
data = SIGNAL.data;
fsHz = SIGNAL.fsHz;


%% GET CUE-RELATED SETINGS 
% 
% 
% Copy settings
SET = CUE.set;


%% INITIALIZE FRAME-BASED PROCESSING
% 
% 
% Compute framing parameters
wSize = 2 * round(SET.wSizeSec * fsHz / 2);
hSize = 2 * round(SET.hSizeSec * fsHz / 2);
win   = window(SET.winType,wSize);

% Determine size of input
[nSamples,nFilter,nChannels] = size(data);

% Check if input is binaural
if nChannels ~= 2
    error('Binaural input required.')
end

% Compute number of frames
nFrames = max(floor((nSamples-(wSize-hSize))/hSize),1);


%% COMPUTE ILD
% 
% 
% Allocate memory
ild = zeros(nFilter,nFrames);

% Loop over number of auditory filters
for ii = 1 : nFilter
    
    % Framing
    frames_L = frameData(data(:,ii,1),wSize,hSize,win,false);
    frames_R = frameData(data(:,ii,2),wSize,hSize,win,false);
    
    % Compute energy
    energyL = mean(power(frames_L,2),1);
    energyR = mean(power(frames_R,2),1);
    
    % Calculate interaural level difference
    ild(ii,:) = 10 * (log10(energyR + eps) - log10(energyL + eps));
end


%% UPDATE CUE STRUCTURE
% 
% 
% Copy signal
CUE.data = ild;


%   ***********************************************************************
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
% 
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
% 
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%   ***********************************************************************