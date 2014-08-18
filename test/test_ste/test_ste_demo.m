% Add necessary paths
addpath('..');
repoRoot = add_WP_paths;
addpath(genpath(fullfile(repoRoot, 'TwoEarsRUB')));

%clearAllButBreakpoints;
close all;
clc;


%% load ste scene

fs = 44100;
basicTimeStep = 0.02; % for scene processing

if ~exist( 'ste.mat', 'file' )
    
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
    
    [lt, lm, ln] = testWrapper.renderLabels( 1 / basicTimeStep );
    % Generate output signal
    targetToMaskerSNR = 20; % Target-to-Masker SNR in dB
    targetToNoiseSNR = 300; % Target-to-Noise SNR in dB
    steSound = testWrapper.renderSignals(targetToMaskerSNR, targetToNoiseSNR);
    
    % save for later use
    save( [repoRoot filesep 'TwoEarsRUB' filesep 'ste.mat'], 'steSound', 'fs', 'lt', 'ln', 'lm', 'targetToMaskerSNR', 'targetToNoiseSNR', 'file1', 'file2', 'file3' );
    
else
    load( [repoRoot filesep 'TwoEarsRUB' filesep 'ste.mat'], 'steSound', 'fs', 'lt', 'ln', 'lm', 'targetToMaskerSNR', 'targetToNoiseSNR', 'file1', 'file2', 'file3' );    
end

%% Play output signal
%soundsc(out, fs)


%% set up scene "live" processing

staticSim = PrecompiledSimFake( steSound, fs );

% Create blackboard. 1 makes KSs to print more information
bb = Blackboard(0);

% Peripheral simulator KS:
ksPeriphSim = Wp1Wp2KS( bb, fs, staticSim, basicTimeStep, 0.5 ); % 0.02 -> basic time step, 0.5 -> max blocklenght in s
bb.addKS(ksPeriphSim);

ksIdentity1 = IdentityKS( bb, 'baby', 'e39682bfc16bde30164ac58f516df09e' );
bb.addKS( ksIdentity1 );
ksIdentity2 = IdentityKS( bb, 'femaleSpeech', 'e39682bfc16bde30164ac58f516df09e' );
bb.addKS( ksIdentity2 );

IdentityKS.createProcessors( ksPeriphSim, ksIdentity1 );
IdentityKS.createProcessors( ksPeriphSim, ksIdentity2 );

% TODO: add IdentityPlausabilityKS
% register to IdentityHypothesis event
% and in case of confusion, notify with SharpenIdentityEars event

% TODO: add IdentitySharpenKS
% register to SharpenIdentityEars event -> modify identityKSs

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

figure;
babyHyps = bb.identityHypotheses(strcmpi({bb.identityHypotheses.label},'baby'));
femaleHyps = bb.identityHypotheses(strcmpi({bb.identityHypotheses.label},'femaleSpeech'));
babyProbs = cell2mat( {babyHyps.p} );
femaleProbs = cell2mat( {femaleHyps.p} );
sceneLen_steps = max( length(lt), length(babyProbs) );
if length(lt) < sceneLen_steps
    lt = [lt zeros(1,sceneLen_steps-length(lt))];
end
if length(lm) < sceneLen_steps
    lm = [lm zeros(1,sceneLen_steps-length(lm))];
end
if length(ln) < sceneLen_steps
    ln = [ln zeros(1,sceneLen_steps-length(ln))];
end
if length(babyProbs) < sceneLen_steps
    babyProbs = [babyProbs zeros(1,sceneLen_steps-length(babyProbs))];
end
if length(femaleProbs) < sceneLen_steps
    femaleProbs = [femaleProbs zeros(1,sceneLen_steps-length(femaleProbs))];
end
t = (1:sceneLen_steps) * basicTimeStep;
plot( t, babyProbs, t, femaleProbs, t, lt, t, lm );
