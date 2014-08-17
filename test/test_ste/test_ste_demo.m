% Add necessary paths
addpath('..');
repoRoot = add_WP_paths;
addpath(genpath(fullfile(repoRoot, 'TwoEarsRUB')));

%clearAllButBreakpoints;
close all;
clc;


%% load ste scene

fs = 44100;

if ~exist( 'ste_scene.wav', 'file' )
    
    %% if it doesn't exist, create the scene
    % Create an instance of the simulation wrapper class
    testWrapper = SimulationWrapper('test_ste.xml');
    
    % Specify audio file paths
    file1 = fullfile('/TwoEarsRUB/baby.wav');
    file2 = fullfile('/TwoEarsRUB/test/femaleSpeech/bbad2n.wav');
    file3 = fullfile('/TwoEarsRUB/test/fire/FireHouse+CRB02_24.wav');
    
    % Add files to the class instance
    testWrapper.addTargetSignal(file1, 0);
    testWrapper.addMaskerSignal(file2, 270);
    testWrapper.addNoiseSignal(file3);
    
    % Generate output signal
    targetToMaskerSNR = 20; % Target-to-Masker SNR in dB
    targetToNoiseSNR = 300; % Target-to-Noise SNR in dB
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

%% Play output signal
%soundsc(out, fs)


%% set up scene "live" processing

staticSim = PrecompiledSimFake( steSound, fs );

% Create blackboard. 1 makes KSs to print more information
bb = Blackboard(0);

% Peripheral simulator KS:
ksPeriphSim = Wp1Wp2KS( bb, fs, staticSim, 0.02, 0.5 ); % 0.02 -> basic time step, 0.5 -> max blocklenght in s
bb.addKS(ksPeriphSim);

ksIdentity1 = IdentityKS( bb, 'baby', 'e39682bfc16bde30164ac58f516df09e' );
bb.addKS( ksIdentity1 );
ksIdentity2 = IdentityKS( bb, 'femaleSpeech', 'e39682bfc16bde30164ac58f516df09e' );
bb.addKS( ksIdentity2 );

IdentityKS.createProcessors( ksPeriphSim, ksIdentity1 );
IdentityKS.createProcessors( ksPeriphSim, ksIdentity2 );

% Register events with a list of KSs that should be triggered
bm = BlackboardMonitor(bb);
bm.registerEvent('NextSoundUpdate', ksPeriphSim);
bm.registerEvent('NewWp2Signal', ksIdentity1);
bm.registerEvent('NewWp2Signal', ksIdentity2);

%% Start the scene "live" processing

scheduler = Scheduler(bm);
while ~staticSim.isFinished()
    bb.setReadyForNextBlock();
    while scheduler.iterate(), end;
end
%% evaluation


