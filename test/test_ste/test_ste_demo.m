clearAllButBreakpoints;
close all;
clc;

% Add necessary paths
addpath('..');
repoRoot = add_WP_paths;
addpath(genpath(fullfile(repoRoot, 'TwoEarsRUB')));


%% load ste scene

fs = 44100;

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
    
    [steSound, fsWav] = audioread( 'ste_scene.wav' );
    if fsWav ~= fs
        fprintf( '\nWarning: sound is resampled from %uHz to %uHz\n', fsWav, fs );
        steSound = resample( steSound, fs, fsWav );
    end
    
end

staticSim = PrecompiledSimFake( steSound, fs );

%% Play output signal
%soundsc(out, fs)


%% set up scene "live" processing

% Create blackboard. 1 makes KSs to print more information
bb = Blackboard(1);

% Initialise Knowledge Sources
ksSignalBlock = SignalBlockKS( bb, staticSim, 0.5 ); % 0.5 -> blocklenght in s
bb.addKS(ksSignalBlock);

ksWp2 = Wp2KS( bb, fs );
bb.addKS(ksWp2);

ksAcousticCues = AcousticCuesKS(bb, wp2dataObj);
bb.addKS(ksAcousticCues);


% Register events with a list of KSs that should be triggered
bm = BlackboardMonitor(bb);
bm.registerEvent('ReadyForNextBlock', ksSignalBlock);
bm.registerEvent('NewSignalBlock', ksWp2);
bm.registerEvent('NewWp2Signal', ksAcousticCues);
%bm.registerEvent('NewAcousticCues', []);

if plotting
    %% Add event listeners for plotting
    addlistener(bb, 'NewSignalBlock', @plotSignalBlocks);
    addlistener(bb, 'NewWp2Signal', @plotPeripherySignal);
    addlistener(bb, 'NewAcousticCues', @plotAcousticCues);
    figure(1)
    movegui('northwest');
end

%% Start the bb scheduler
bb.setReadyForNextBlock(true);
scheduler = Scheduler(bm);
ok = scheduler.iterate;
while ok
    ok = scheduler.iterate;
end


