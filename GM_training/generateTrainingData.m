function generateTrainingData(dataPath, angles, trainDurationSec)
%
% dataPath              Path for saving training data
% angles                A vector of angles to be processed, eg, [0:5:355]
% trainDurationSec      Duration of training data in seconds (default 4)
%

%% Handle in arguments

if ~exist(dataPath, 'dir')
    mkdir(dataPath);
end
numAngles = length(angles);
if nargin < 3
    trainDurationSec = 4;
end

%% Initialize simulation parameters

% Initialize  simulation parameters (at the moment, just the 'default'
% setting is supported)
simParams = initSimulationParameters('fa2014');

%% Initialize all WP2 related parameters

% Specify cues that should be computed
strCues = {'itd_xcorr' 'ild' 'ic_xcorr' 'ratemap_magnitude'};

% Specify features that should be extracted
strFeatures = {};

% Initialize WP2 parameter struct
wp2States = init_WP2(strFeatures, strCues, simParams);

%% Generate features

for k = 1 : numAngles
    % Initialize training scene
    scene = initTrainingScene(trainDurationSec, angles(k), simParams);
    
    %% Initialize blackboard, KSs and the blackboard monitor
    
    % Create blackboard instance
    bb = Blackboard(scene);
    
    % Init SignalBlockKS
    ksSignalBlock = SignalBlockKS(bb);
    bb.addKS(ksSignalBlock);
    ksPeriphery = PeripheryKS(bb, simParams, wp2States);
    bb.addKS(ksPeriphery);
    ksAcousticCues = AcousticCuesKS(bb, wp2States);
    bb.addKS(ksAcousticCues);
    ksCueSaving = AcousticCueSavingKS(bb, dataPath, k-1);
    bb.addKS(ksCueSaving);

    % Register events with a list of KSs that should be triggered
    bm = BlackboardMonitor(bb);
    bm.registerEvent('ReadyForNextBlock', ksSignalBlock);
    bm.registerEvent('NewSignalBlock', ksPeriphery);
    bm.registerEvent('NewPeripherySignal', ksAcousticCues);
    bm.registerEvent('NewAcousticCues', ksCueSaving);

    % Start the scheduler
    bb.setReadyForNextBlock(true);
    scheduler = Scheduler(bm);
    ok = scheduler.iterate;
    while ok
        ok = scheduler.iterate;
    end
        
    fprintf('\n');
end
