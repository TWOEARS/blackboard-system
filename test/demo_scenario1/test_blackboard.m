function [locErrors, srcPositions] = test_blackboard(snr)

addpath('../../src');
startWP3;

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
        ksLoc = LocationKS(bb, gmName, dimFeatures, angles);
        bb.addKS(ksLoc);
        ksConf = ConfusionKS(bb);
        bb.addKS(ksConf);
        ksConfSolver = ConfusionSolvingKS(bb);
        bb.addKS(ksConfSolver);
        ksRotate = RotationKS(bb);
        bb.addKS(ksRotate);

        % Register events with a list of KSs that should be triggered
        bm = BlackboardMonitor(bb);
        bm.registerEvent('ReadyForNextBlock', ksSignalBlock);
        bm.registerEvent('NewSignalBlock', ksPeriphery);
        bm.registerEvent('NewPeripherySignal', ksAcousticCues);
        bm.registerEvent('NewAcousticCues', ksLoc);
        bm.registerEvent('NewLocationHypothesis', ksConf, ksConfSolver);
        bm.registerEvent('NewConfusionHypothesis', ksRotate);

        if plotting
            %% Add event listeners for plotting
            addlistener(bb, 'NewSignalBlock', @plotSignalBlocks);
            addlistener(bb, 'NewPeripherySignal', @plotPeripherySignal);
            addlistener(bb, 'NewAcousticCues', @plotAcousticCues);
            addlistener(bb, 'NewLocationHypothesis', @plotLocationHypothesis);
            addlistener(bb, 'NewPerceivedLocation', @plotPerceivedLocation);
            figure(1)
            movegui('northwest');
        end

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
            save('localisation_errors_BB_clean', 'locErrors', 'srcPositions');
        else
            save(sprintf('localisation_errors_BB_%s_%ddB', envNoiseType, snr), 'locErrors', 'srcPositions');
        end
    end
end




%% Plotting functions
function plotSignalBlocks(bb, evnt)
sigBlock = bb.signalBlocks{evnt.data};
subplot(4, 4, [15, 16])
plot(sigBlock.signals(:,1));
axis tight; ylim([-1 1]);
xlabel('k');
title(sprintf('Block %d, head orientation: %d deg, left ear waveform', sigBlock.blockNo, sigBlock.headOrientation), 'FontSize', 12);

subplot(4, 4, [13, 14])
plot(sigBlock.signals(:,2));
axis tight; ylim([-1 1]);
xlabel('k');
title(sprintf('Block %d, head orientation: %d deg, right ear waveform', sigBlock.blockNo, sigBlock.headOrientation), 'FontSize', 12);
%soundsc([sigBlock.signals(:,1), sigBlock.signals(:,2)], 44100)

function plotPeripherySignal(bb, evnt)
sigBlock = bb.peripherySignals{evnt.data};
subplot(4, 4, [11, 12])
imagesc(sigBlock.signals(3).data(:, :, 1)');
set(gca,'YDir','normal');
ylabel('GFB Channels');
xlabel('k');
title(sprintf('Block %d, head orientation: %d deg, left ear IHC', sigBlock.blockNo, sigBlock.headOrientation), 'FontSize', 12);

subplot(4, 4, [9, 10])
imagesc(sigBlock.signals(3).data(:, :, 2)');
set(gca,'YDir','normal');
ylabel('GFB Channels');
xlabel('k');      
title(sprintf('Block %d, head orientation: %d deg, right ear IHC', sigBlock.blockNo, sigBlock.headOrientation), 'FontSize', 12);


function plotAcousticCues(bb, evnt)
acousticCue = bb.acousticCues{evnt.data};
subplot(4, 4, 5)
imagesc(acousticCue.itds);
set(gca,'YDir','normal');
ylabel('GFB Channels');
xlabel('Frame index');
caxis([-1 1]);
title(sprintf('Block %d, head orientation: %d deg, ITD', acousticCue.blockNo, acousticCue.headOrientation), 'FontSize', 12);

subplot(4, 4, 6)
imagesc(acousticCue.ilds);
set(gca,'YDir','normal');
ylabel('GFB Channels');
xlabel('Frame index');   
caxis([-10 10]);
title(sprintf('Block %d, head orientation: %d deg, ILD', acousticCue.blockNo, acousticCue.headOrientation), 'FontSize', 12);

subplot(4, 4, 7)
imagesc(acousticCue.ic);
set(gca,'YDir','normal');
ylabel('GFB Channels');
xlabel('Frame index');   
caxis([0 1]);
title(sprintf('Block %d, head orientation: %d deg, IC', acousticCue.blockNo, acousticCue.headOrientation), 'FontSize', 12);

subplot(4, 4, 8)
imagesc(acousticCue.ratemap(:, :, 1));
set(gca,'YDir','normal');
ylabel('GFB Channels');
xlabel('Frame index');   
caxis([0 1]);
title(sprintf('Block %d, head orientation: %d deg, RATEMAP', acousticCue.blockNo, acousticCue.headOrientation), 'FontSize', 12);
drawnow


function plotLocationHypothesis(bb, evnt)
subplot(4, 4, [1, 2])
locHyp = bb.locationHypotheses(evnt.data);
bar(locHyp.locations, locHyp.posteriors);
xlabel('Azimuth (degrees)', 'FontSize', 12);
ylabel('Probability', 'FontSize', 12);
axis([0 361 0 1]);
title(sprintf('Block %d, head orientation: %d deg, distribution', locHyp.blockNo, locHyp.headOrientation), 'FontSize', 12);
%colormap(summer);


function plotPerceivedLocation(bb, evnt)
subplot(4, 4, [3, 4])
pLoc = bb.perceivedLocations(evnt.data(1));
bar(pLoc.location, pLoc.score);
xlabel('Azimuth (degrees)', 'FontSize', 12);
ylabel('Probability', 'FontSize', 12);
axis([0 361 0 1]);
title(sprintf('Block %d, head orientation: %d deg, perceived location', pLoc.blockNo, pLoc.headOrientation), 'FontSize', 12);
