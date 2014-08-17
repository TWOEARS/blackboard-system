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

% Peripheral simulator KS:
ksPeriphSim = Wp1Wp2KS( bb, fs, staticSim, 0.02, 0.5 ); % 0.02 -> basic time step, 0.5 -> max blocklenght in s
bb.addKS(ksPeriphSim);

ksIdentity = IdentityKS( bb, 'baby', 'e39682bfc16bde30164ac58f516df09e' );
bb.addKS( ksIdentity );

IdentityKS.createProcessors( ksPeriphSim, ksIdentity );

% Register events with a list of KSs that should be triggered
bm = BlackboardMonitor(bb);
bm.registerEvent('ReadyForNextBlock', ksSignalBlock);
bm.registerEvent('NewSignalBlock', ksWp2);
bm.registerEvent('NewWp2Signal', ksIdentity);

% if plotting
%     %% Add event listeners for plotting
%     addlistener(bb, 'NewSignalBlock', @SignalBlockKS.plotSignalBlocks);
%     figure(1)
%     movegui('northwest');
% end

%% Start the scene "live" processing

bb.setReadyForNextBlock(true);
scheduler = Scheduler(bm);
ok = scheduler.iterate;
while ok
    ok = scheduler.iterate;
end

%% evaluation


