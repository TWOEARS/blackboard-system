%function test_ste(soundfile)
% TEST_STE Test script for the "Sharpening the Ears" task
%
% Inputs:
%   sceneXML - XML file describing the scene that should be analyzed
%
% Christopher Schymura, 12 August 2014
% christopher.schymura@rub.de

clear all;
clc;

% DEBUG
numUtterances = 10;
azimuth = 90;

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

% This test script picks a random speaker from the GRID Corpus and
% concatenates a specified number of utternaces of that speaker to generate
% the audio signals.

% Get random ID for the target speaker (34 speakers in the GRID Corpus)
speakerID = randi(34);

% Get file list from folder
fileList = dir(fullfile([repoRoot, ...
    '/twoears-data/sound_databases/grid_subset/wav/s', num2str(speakerID)]));

% Remove dots at the beginning of the file list
fileList = fileList(3 : end);

% Get number of available sound files
numFiles = length(fileList);

% Randomly pick files from the list
fileIDs = randi(numFiles, numUtterances, 1);

% Allocate signal vector
signal = [];

% Load and concatenate sound files
for k = 1 : numUtterances
    % Read audio
    [input, fsHz] = audioread(fullfile([repoRoot, ...
        '/twoears-data/sound_databases/grid_subset/wav/s', ...
        num2str(speakerID), '/', fileList(fileIDs(k)).name]));

    % Upsample if necessary
    if fsHz ~= sim.SampleRate
        input = resample(input, sim.SampleRate, fsHz);
    end
    input = input ./ max(input(:));
    
    % Concatenate audio
    signal = [signal; input];
end

%% Setup simulation

% Fill speech buffer
sim.Sources(1).setData(signal);

% Set source azimuth
sim.Sources(1).set('Azimuth', azimuth);

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
  sim.set('Refresh',true);
  sim.set('Process',true);
%   s = sim.getSignal(0.5);
%   mObj.processChunk(s);
end

out = sim.Sinks.getData();
out = out/max(abs(out(:))); % normalize
audiowrite('out_event.wav',out,sim.SampleRate);


%% clean up
sim.set('ShutDown',true);

%clear all;