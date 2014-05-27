function test_gmms

%% Add relevant paths
addpath('blackboard');
addpath('gmtk');
addpath(genpath('simulator'));
addpath(genpath('wp2'));

%% Initialize simulation

% Name of the graphical model
gmName = 'fa2014';

% Initialize  simulation parameters (at the moment, just the 'default'
% setting is supported)
simParams = initSimulationParameters(gmName);

% Some global settings
dimFeatures = (simParams.nChannels-1) * 2;

% Define angular resolution
numAngles = 360 / simParams.angularResolution;
angles = linspace(0, 360 - simParams.angularResolution, numAngles);
   
%% Initialize all WP2 related parameters

% Specify cues that should be computed
strCues = {'itd_xcorr' 'ild' 'ic_xcorr' 'ratemap_magnitude'};

% Specify features that should be extracted
strFeatures = {};

% Initialize WP2 parameter struct
wp2States = init_WP2(strFeatures, strCues, simParams);


wavfn = 'fa2014_GRID_data/test/s1/lbayzp.wav';
srcPositions = [330]; %[270 300 330 0 30 60 90];
nPositions = length(srcPositions);
errorRates = zeros(nPositions, 1);
for p=1:nPositions
    srcPos = srcPositions(p);

    % Initialize scene to be simulated.
    src = SoundSource('Speech', wavfn, 'Polar', [1, srcPos]);
    % Define dummy head
    dummyHead = Head('QU_KEMAR_anechoic_3m.mat', simParams.fsHz);
    % Create scene
    scene = Scene(src.numSamples/src.fs, simParams.fsHz, simParams.blockSize * simParams.fsHz, ...
        simParams.blockSize * simParams.fsHz, dummyHead, src);

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
    ksLoc = SimpleGMMLocalisationKS(bb, gmName, dimFeatures, angles);
    bb.addKS(ksLoc);

    % Register events with a list of KSs that should be triggered
    bm = BlackboardMonitor(bb);
    bm.registerEvent('ReadyForNextBlock', ksSignalBlock);
    bm.registerEvent('NewSignalBlock', ksPeriphery);
    bm.registerEvent('NewPeripherySignal', ksAcousticCues);
    bm.registerEvent('NewAcousticCues', ksLoc);


    %% Start the scheduler
    bb.setReadyForNextBlock(true);
    scheduler = Scheduler(bm);
    ok = scheduler.iterate;
    while ok
        ok = scheduler.iterate;
    end

    fprintf('\n---------------------------------------------------------------------------\n');
    fprintf('Source location: %d degrees\n', srcPos);
    fprintf('---------------------------------------------------------------------------\n');
    fprintf('Perceived source locations (* indicates confusion)\n');
    fprintf('---------------------------------------------------------------------------\n');
    fprintf('Block\tLocation   (head orientation    relative location)\tProbability\n');
    fprintf('---------------------------------------------------------------------------\n');

    estLocations = zeros(bb.getNumPerceivedLocations, 1);

    for n=1:bb.getNumPerceivedLocations
        fprintf('%d\t%d degrees\t(%d degrees\t%d degrees)\t\t%.2f\n', ...
            bb.perceivedLocations(n).blockNo, ...
            bb.perceivedLocations(n).location + bb.perceivedLocations(n).headOrientation, ...
            bb.perceivedLocations(n).headOrientation, ...
            bb.perceivedLocations(n).location, ...
            bb.perceivedLocations(n).score);

        estLocations(n) = bb.perceivedLocations(n).location + ...
            bb.perceivedLocations(n).headOrientation;
    end
    fprintf('---------------------------------------------------------------------------\n');

    errorRates(p) = 1 / length(estLocations) * sum(abs(estLocations - ...
        srcPos * ones(bb.getNumPerceivedLocations, 1)));

    fprintf('Mean localisation error: %.4f degrees\n', errorRates(p));
    fprintf('---------------------------------------------------------------------------\n');
end

errorRates


