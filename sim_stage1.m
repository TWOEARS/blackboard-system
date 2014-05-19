function sim_stage1

clc;
clear all;

addpath(genpath(pwd));


%% Initialize simulation

% Name of the graphical model
gmName = 'stage1';

% Initialize  simulation parameters (at the moment, just the 'default'
% setting is supported)
simParams = initSimulationParameters('default');

% Some global settings
dimFeatures = (simParams.nChannels-1) * 2;

% Define angular resolution
numAngles = 360 / simParams.angularResolution;
angles = linspace(0, 360 - simParams.angularResolution, numAngles);

% Initialize scene to be simulated.
% Select between 'stage1_freefield' or 'stage1_reverb'
%
% WARNING: HRIRs for freefield conditions have changed but GM has not
% been retrained yet.
[scene, sourcePos, out] = initSceneParameters('stage1_freefield', simParams);

%% Initialize all WP2 related parameters

% Specify cues that should be computed
strCues = {'itd_xcorr' 'ild' 'ic_xcorr' 'ratemap_magnitude'};

% Specify features that should be extracted
strFeatures = {};

% Initialize WP2 parameter struct
wp2States = init_WP2(strFeatures, strCues, simParams);

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
ksRotate = RotationKS(bb, simParams.headRotateAngle);
bb.addKS(ksRotate);

% Register events with a list of KSs that should be triggered
bm = BlackboardMonitor(bb);
bm.registerEvent('ReadyForNextBlock', ksSignalBlock);
bm.registerEvent('NewSignalBlock', ksPeriphery);
bm.registerEvent('NewPeripherySignal', ksAcousticCues);
bm.registerEvent('NewAcousticCues', ksLoc);
bm.registerEvent('NewLocationHypothesis', ksConf, ksConfSolver);
bm.registerEvent('NewConfusionHypothesis', ksRotate);

%% Add event listeners for plotting
addlistener(bb, 'NewSignalBlock', @plotSignalBlocks);
addlistener(bb, 'NewPeripherySignal', @plotPeripherySignal);
addlistener(bb, 'NewAcousticCues', @plotAcousticCues);
addlistener(bb, 'NewLocationHypothesis', @plotLocationHypothesis);
addlistener(bb, 'NewPerceivedLocation', @plotPerceivedLocation);
figure(1)
movegui('northwest');
    
%% Start the scheduler
bb.setReadyForNextBlock(true);
scheduler = Scheduler(bm);
ok = scheduler.iterate;
while ok
    ok = scheduler.iterate;
end

fprintf('\n---------------------------------------------------------------------------\n');
fprintf('Source location: %d degrees\n', sourcePos);
fprintf('---------------------------------------------------------------------------\n');
fprintf('Perceived source locations (* indicates confusion)\n');
fprintf('---------------------------------------------------------------------------\n');
fprintf('Block\tLocation   (head orientation    relative location)\tProbability\n');
fprintf('---------------------------------------------------------------------------\n');
for n=1:bb.getNumPerceivedLocations
    fprintf('%d\t%d degrees\t(%d degrees\t%d degrees)\t\t%.2f\n', ...
        bb.perceivedLocations(n).blockNo, ...
        bb.perceivedLocations(n).location + bb.perceivedLocations(n).headOrientation, ...
        bb.perceivedLocations(n).headOrientation, ...
        bb.perceivedLocations(n).location, ...
        bb.perceivedLocations(n).score);
end
fprintf('---------------------------------------------------------------------------\n');
for n=1:bb.getNumConfusionHypotheses
    cf = bb.confusionHypotheses(n);
    if cf.seenByConfusionSolvingKS == false
        for m=1:length(cf.locations)
            fprintf('*%d\t%d degrees\t(%d degrees\t%d degrees)\t\t%.2f\n', ...
                cf.blockNo, cf.locations(m)+cf.headOrientation, cf.headOrientation, cf.locations(m), cf.posteriors(m));
        end
    end
end
fprintf('---------------------------------------------------------------------------\n');


%% Plotting functions
function plotSignalBlocks(bb, evnt)
sigBlock = bb.signalBlocks{evnt.data};
subplot(4, 4, [13, 14])
plot(sigBlock.signals(:,1));
axis tight; ylim([-5 5]);
xlabel('Time', 'FontSize', 12);
title(sprintf('Left ear waveform'), 'FontSize', 14);

subplot(4, 4, [15, 16])
plot(sigBlock.signals(:,2));
axis tight; ylim([-5 5]);
xlabel('Time', 'FontSize', 12);
title(sprintf('Right ear waveform'), 'FontSize', 14);

function plotPeripherySignal(bb, evnt)
sigBlock = bb.peripherySignals{evnt.data};
subplot(4, 4, [9, 10])
imagesc(sigBlock.signals(3).data(:, :, 1)');
set(gca,'YDir','normal');
ylabel('GFB Channels', 'FontSize', 12);
xlabel('Time', 'FontSize', 12);
title(sprintf('Left ear IHC'), 'FontSize', 14);

subplot(4, 4, [11, 12])
imagesc(sigBlock.signals(3).data(:, :, 2)');
set(gca,'YDir','normal');
ylabel('GFB Channels');
xlabel('Time', 'FontSize', 12);    
title(sprintf('Right ear IHC'), 'FontSize', 14);


function plotAcousticCues(bb, evnt)
acousticCue = bb.acousticCues{evnt.data};
subplot(4, 4, 5)
imagesc(acousticCue.itds);
set(gca,'YDir','normal');
ylabel('GFB Channels', 'FontSize', 12);
xlabel('Frame index', 'FontSize', 12);
caxis([-1 1]);
title(sprintf('Interaural Time Difference (ITD)'), 'FontSize', 14);

subplot(4, 4, 6)
imagesc(acousticCue.ilds);
axis xy
set(gca,'YDir','normal');
%ylabel('GFB Channels', 'FontSize', 12);
xlabel('Frame index', 'FontSize', 12); 
caxis([-10 10]);
title('Interaural Level Difference (ILD)', 'FontSize', 14);

subplot(4, 4, 7)
imagesc(acousticCue.ic);
axis xy
set(gca,'YDir','normal');
%ylabel('GFB Channels', 'FontSize', 12);
xlabel('Frame index', 'FontSize', 12);  
caxis([0 1]);
title('Interaural Coherence (IC)', 'FontSize', 14);

subplot(4, 4, 8)
imagesc(acousticCue.ratemap(:, :, 1));
axis xy
set(gca,'YDir','normal');
%ylabel('GFB Channels', 'FontSize', 12);
xlabel('Frame index', 'FontSize', 12);   
%caxis([0 1]);
title('RATEMAP', 'FontSize', 14);
drawnow


function plotLocationHypothesis(bb, evnt)
subplot(4, 4, [1, 2])
locHyp = bb.locationHypotheses(evnt.data);
bar(locHyp.locations, locHyp.posteriors, 'FaceColor',[0.75 0.87 0.77], 'EdgeColor',[0.23 0.44 0.34]);
xlabel('Azimuth (degrees)', 'FontSize', 12);
ylabel('Probability', 'FontSize', 12);
axis([0 361 0 1]);
title('Probability distribution for all azimuth locations', 'FontSize', 14);


function plotPerceivedLocation(bb, evnt)
subplot(4, 4, [3, 4])
pLoc = bb.perceivedLocations(evnt.data(1));
bar(pLoc.location, pLoc.score);
xlabel('Azimuth (degrees)', 'FontSize', 12);
ylabel('Probability', 'FontSize', 12);
axis([0 361 0 1]);
title(sprintf('Perceived source location. Current head orientation: %d deg', pLoc.headOrientation), 'FontSize', 14);


%%