clear all;
close all;
clc;

% Add necessary paths
addpath('..');
repoRoot = add_WP_paths;

% Create an instance of the simulation wrapper class
testWrapper = SimulationWrapper('test_ste.xml');

% Specify audio file paths
file1 = fullfile('/sound_databases/grid_subset/wav/s1/bbas2p.wav');
file2 = fullfile('/sound_databases/grid_subset/wav/s2/bbie8s.wav');
file3 = fullfile('/stimuli/binaural/binaural_forest.wav');

% Add files to the class instance
testWrapper.addTargetSignal(file1, 90);
testWrapper.addMaskerSignal(file2, 270);
testWrapper.addNoiseSignal(file3);

% Generate output signal
targetToMaskerSNR = 15; % Target-to-Masker SNR in dB
targetToNoiseSNR = 15; % Target-to-Noise SNR in dB
out = testWrapper.renderSignals(targetToMaskerSNR, targetToNoiseSNR);

% Play output signal
soundsc(out, 44100)