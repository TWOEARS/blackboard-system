%function test_ste
% TEST_STE Test script for the "Sharpening the Ears" task
%
% Christopher Schymura, 12 August 2014
% christopher.schymura@rub.de

clear all;
clc;

% DEBUG
numUtterances = 10;
azimuthTarget = 90;
azimuthMasker = 270;

%% Error and parameter handling

% Add relevant paths to Matlab search path and get repository root
addpath('..');
repoRoot = add_WP_paths;

%% Initialize simulation environment

% Import XML and simulation functionalities
import xml.*
import simulator.*

% Initialize SSR
sim = SimulatorConvexRoom();  % simulator object
sim.loadConfig('test_ste.xml');
sim.set('Init',true);

%% Read audio files

% Get random ID for the target speaker (34 speakers in the GRID Corpus)
targetID = randi(34);

% Get random ID for the masking speaker
maskerID = targetID;
while maskerID == targetID
    maskerID = randi(34);
end

% Get file lists for both speakers from subfolders
fileListTarget = dir(fullfile([repoRoot, ...
    '/twoears-data/sound_databases/grid_subset/wav/s', num2str(targetID)]));
fileListMasker = dir(fullfile([repoRoot, ...
    '/twoears-data/sound_databases/grid_subset/wav/s', num2str(maskerID)]));

% Remove dots at the beginning of the file list
fileListTarget = fileListTarget(3 : end);
fileListMasker = fileListMasker(3 : end);

% Get number of available sound files
numFilesTarget = length(fileListTarget);
numFilesMasker = length(fileListMasker);

% Randomly pick files from the list
fileIDTarget = randi(numFilesTarget, numUtterances, 1);
fileIDMasker = randi(numFilesMasker, numUtterances, 1);

% Allocate signal vectors
signalTarget = [];
signalMasker = [];

% Load and concatenate sound files
for l = 1 : 2
    for k = 1 : numUtterances
        % Get filename and ID
        if l == 1
            id = targetID;
            fileName = fileListTarget(fileIDTarget(k)).name;
        else
            id = maskerID;
            fileName = fileListMasker(fileIDMasker(k)).name;
        end
        
        % Read audio
        [input, fsHz] = audioread(fullfile([repoRoot, ...
            '/twoears-data/sound_databases/grid_subset/wav/s', ...
            num2str(id), '/', fileName]));
        
        % Upsample if necessary
        if fsHz ~= sim.SampleRate
            input = resample(input, sim.SampleRate, fsHz);
        end
        input = input ./ max(input(:));
        
        % Concatenate audio
        if l == 1
            signalTarget = [signalTarget; input];
        else
            signalMasker = [signalMasker; input];
        end
    end
end

%% Setup simulation

% Fill speech buffer
sim.Sources(1).setData(signalTarget);
sim.Sources(2).setData(signalMasker);

% Set source azimuth
sim.Sources(1).set('Azimuth', azimuthTarget);
sim.Sources(2).set('Azimuth', azimuthMasker);

%% Initialise WP2 related parameters

% Framing parameters
blockSec = 20E-3;
stepSec  = 10E-3;

% Gammatone parameters
f_low       = 80;
f_high      = 8000;
nChannels   = 32;
rm_decaySec = 0;

% Frequency range and number of channels
WP2_param = genParStruct('f_low',f_low,'f_high',f_high,...
                         'nChannels',nChannels,...
                         'rm_decaySec',rm_decaySec,...
                         'ild_wSizeSec',blockSec,...
                         'ild_hSizeSec',stepSec,'rm_wSizeSec',blockSec,...
                         'rm_hSizeSec',stepSec,'cc_wSizeSec',blockSec,...
                         'cc_hSizeSec',stepSec);    

% Request cues being extracted
WP2_requests = {'ild' 'itd_xcorr' 'ic_xcorr', 'ratemap_power'};

% Create an empty data object. It will be filled up as new ear signal
% chunks are "acquired". 
dObj = dataObject([], sim.SampleRate, 1);  % Last input (1) indicates a stereo signal
mObj = manager(dObj, WP2_requests, WP2_param);   % Instantiate a manager

%% Main loop

while ~sim.Sources(1).isEmpty();
    %sim.set('Refresh',true);
    %sim.set('Process',true);
    s = sim.getSignal(0.5);
    mObj.processChunk(s);
end

% out = sim.Sinks.getData();
% out = out / max(abs(out(:))); % normalize
% audiowrite('ste_out.wav', out, sim.SampleRate);


%% clean up
sim.set('ShutDown', true);