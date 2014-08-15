clear all;
close all;
clc;

% Add necessary paths
addpath('..');
repoRoot = add_WP_paths;
addpath(genpath(fullfile(repoRoot, 'TwoEarsRUB')));


%% load ste scene

if ~exist( 'ste_scene.wav', 'file' )
    
    %% if it doesn't exist, create the scene
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
    targetToMaskerSNR = 0; % Target-to-Masker SNR in dB
    targetToNoiseSNR = 15; % Target-to-Noise SNR in dB
    steSound = testWrapper.renderSignals(targetToMaskerSNR, targetToNoiseSNR);
    
    % save for later use
    audiowrite( [repoRoot filesep 'TwoEarsRUB' filesep 'ste_scene.wav'], steSound, 44100 );
    
else
    
    %% if it already exists, load the wav
    
    [steSound, fsHz] = audioread( 'ste_scene.wav' );
    if fsHz ~= 44100
        fprintf( '\nWarning: sound is resampled from %uHz to %uHz\n', fsHz, 44100 );
        steSound = resample( steSound, 44100, fsHz );
    end
    
end

%% Play output signal
%soundsc(out, 44100)
