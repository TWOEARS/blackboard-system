% Add necessary paths
addpath('..');
repoRoot = add_WP_paths;
addpath(genpath(fullfile(repoRoot, 'dataGit/sound_databases')));

%clearAllButBreakpoints;
close all;
clc;


%% load ste scene

fs = 44100;
basicTimeStep = 0.1; % for scene processing

if ~exist( 'ste.mat', 'file' )
    
    %% if it doesn't exist, create the scene
    % Create an instance of the simulation wrapper class
    testWrapper = SimulationWrapper('test_ste.xml');
    
    % Specify audio file paths
    file1 = fullfile('HumanBaby+6105_97_1.wav');
    file2 = fullfile('femaleTest.wav');
    file3 = fullfile('fireTest.wav');
    
    % Add files to the class instance
    testWrapper.addTargetSignal(file1, 0, 5 );
    testWrapper.addMaskerSignal(file2, 270, 30 );
    testWrapper.addNoiseSignal(file3);
    
    [lt, lm, ln] = testWrapper.renderLabels( 1 / basicTimeStep );
    % Generate output signal
    targetToMaskerSNR = 0; % Target-to-Masker SNR in dB
    targetToNoiseSNR = 10; % Target-to-Noise SNR in dB
    steSound = testWrapper.renderSignals(targetToMaskerSNR, targetToNoiseSNR);
    
    % save for later use
    save( [repoRoot filesep 'dataGit/sound_databases/renderedScenes' filesep 'ste.mat'], 'steSound', 'fs', 'lt', 'ln', 'lm', 'targetToMaskerSNR', 'targetToNoiseSNR', 'file1', 'file2', 'file3' );
    
else
   load( [repoRoot filesep 'dataGit/sound_databases/renderedScenes' filesep 'ste.mat'], 'steSound', 'fs', 'lt', 'ln', 'lm', 'targetToMaskerSNR', 'targetToNoiseSNR', 'file1', 'file2', 'file3' );    
end

%% Play output signal
%soundsc(out, fs)


%% set up scene "live" processing

staticSim = PrecompiledSimFake( steSound, fs );

% Create blackboard. 1 makes KSs to print more information
bb = Blackboard(0);

% Peripheral simulator KS:
ksPeriphSim = Wp1Wp2KS( bb, staticSim, basicTimeStep, 0.5 ); % 0.02 -> basic time step, 0.5 -> max blocklenght in s
bb.addKS(ksPeriphSim);

ksIdentity1 = IdentityKS( bb, 'baby', 'e39682bfc16bde30164ac58f516df09e' );
bb.addKS( ksIdentity1 );
ksIdentity2 = IdentityKS( bb, 'femaleSpeech', 'e39682bfc16bde30164ac58f516df09e' );
bb.addKS( ksIdentity2 );
ksIdentity3 = IdentityKS( bb, 'fire', 'e39682bfc16bde30164ac58f516df09e' );
bb.addKS( ksIdentity3 );

IdentityKS.createProcessors( ksPeriphSim, ksIdentity1 );
IdentityKS.createProcessors( ksPeriphSim, ksIdentity2 );
IdentityKS.createProcessors( ksPeriphSim, ksIdentity3 );

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
bm.registerEvent('NewWp2Signal', ksIdentity3);

%% Start the scene "live" processing

scheduler = Scheduler(bm);
while ~staticSim.isFinished()
    bb.setReadyForNextBlock();
    while scheduler.iterate(), end;
end

%% evaluation

babyHyps = bb.identityHypotheses(strcmpi({bb.identityHypotheses.label},'baby'));
femaleHyps = bb.identityHypotheses(strcmpi({bb.identityHypotheses.label},'femaleSpeech'));
fireHyps = bb.identityHypotheses(strcmpi({bb.identityHypotheses.label},'fire'));
fireProbs = cell2mat( {fireHyps.p} );
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
if length(fireProbs) < sceneLen_steps
    fireProbs = [fireProbs zeros(1,sceneLen_steps-length(fireProbs))];
end
t = (1:sceneLen_steps) * basicTimeStep;

figure1 = figure( 'Name','label probabilities' );
axes1 = axes( 'Parent',figure1,'YTickLabel',{'0','0,33','0,5','0,66','1'},...
    'YTick',[0 0.33 0.5 0.66 1],...
    'YGrid','on' );
xlim( axes1,[-0.05 (sceneLen_steps * basicTimeStep + 0.05)] );
ylim( axes1,[-0.05 1.05] );
box( axes1,'on' );
hold( axes1,'all' );
plot1 = plot( t, babyProbs, t, femaleProbs, t, lt, t, lm , t, fireProbs, 'Parent',axes1,'LineWidth',2);
set( plot1(1),...
    'Color',[0.05 0.5 0.8],...
    'DisplayName','baby model' );
set( plot1(2),'Color',[0.05 0.8 0.5],...
    'DisplayName','female model' );
set( plot1(3),'LineStyle',':',...
    'Color',[0.05 0.5 0.8],...
    'DisplayName','baby true' );
set( plot1(4),'LineStyle',':',...
    'Color',[0.05 0.8 0.5],...
    'DisplayName','female true' );
set( plot1(5),'LineStyle','-.',...
    'Color',[0.85 0.15 0],...
    'DisplayName','fire model' );
title( 'Label Probabilities' );
xlabel( 't (s)' );
ylabel( 'p' );
legend1 = legend( axes1,'show' );
set( legend1,'Location','Best' );
