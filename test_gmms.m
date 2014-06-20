function [locErrors, srcPositions] = test_gmms(snr)

%% Testing parameters
if nargin < 1
    snr = inf;
end
envNoiseType = 'busystreet';
srcPositions = [270 300 330 0 30 60 90];
flist = 'fa2014_GRID_data/testset.flist';

%% Add relevant paths
addpath('blackboard');
addpath('gmtk');
addpath(genpath('simulator'));
addpath(genpath('wp2'));

plotting = 0;

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

fid = fopen(flist);
C = textscan(fid, '%s');
fclose(fid);
testFiles = C{1};
clear C;

nFiles = length(testFiles);
nPositions = length(srcPositions);
locErrors = zeros(nPositions, nFiles);

for p=1:nPositions
    srcPos = srcPositions(p);
    
    for f=1:nFiles
        clc;
        fprintf('---- Localising target source at %d degrees: file %d (%s)\n', srcPos, f, testFiles{f});
        
        % Initialize scene to be simulated.
        scene = create_scene(simParams, srcPos, testFiles{f}, snr, envNoiseType);

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

        if plotting
            fprintf('\n---------------------------------------------------------------------------\n');
            fprintf('Reference location: %d degrees\n', srcPos);
            fprintf('---------------------------------------------------------------------------\n');
            fprintf('Target source locations\n');
            fprintf('---------------------------------------------------------------------------\n');
            fprintf('Block\tLocation   (head orientation    relative location)\tProbability\n');
            fprintf('---------------------------------------------------------------------------\n');
        end
        
        estLocations = zeros(bb.getNumPerceivedLocations, 1);

        for n=1:bb.getNumPerceivedLocations
            if plotting
                fprintf('%d\t%d degrees\t(%d degrees\t%d degrees)\t\t%.2f\n', ...
                    bb.perceivedLocations(n).blockNo, ...
                    bb.perceivedLocations(n).location + bb.perceivedLocations(n).headOrientation, ...
                    bb.perceivedLocations(n).headOrientation, ...
                    bb.perceivedLocations(n).location, ...
                    bb.perceivedLocations(n).score);
            end
            estLocations(n) = bb.perceivedLocations(n).location + ...
                bb.perceivedLocations(n).headOrientation;
        end
        locErrors(p,f) = mean(calc_localisation_errors(srcPos, estLocations));
    end
    if nargout < 1
        if isinf(snr)
            save('localisation_errors_GMM_clean', 'locErrors', 'srcPositions');
        else
            save(sprintf('localisation_errors_GMM_%s_%ddB', envNoiseType, snr), 'locErrors', 'srcPositions');
        end
    end
end


