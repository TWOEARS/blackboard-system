function sim_stage1

clc;
%clearAllButBreakpoints;
%% Add relevant paths
addpath('blackboard');
addpath('gmtk');
addpath(genpath('simulator'));
addpath(genpath('wp2'));

plotting = 1;

%% Initialize simulation

% Name of the graphical model
%gmName = 'fa2014';
gmName = 'ident';

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
strFeatures = { };

% Initialize WP2 parameter struct
wp2States = init_WP2(strFeatures, strCues, simParams);

srcPos = 30;

%wavfn = 'fa2014_GRID_data/test/s1/lbayzp.wav';
wavfn = 'niEvents_data/test/mix1.wav';

% Initialize scene to be simulated.
%src = SoundSource('Speech', wavfn, 'Polar', [1, srcPos]);
src = SoundSource('EventMix', wavfn, 'Polar', [1, srcPos]);
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
ksLoc = LocationKS(bb, gmName, dimFeatures, angles);
bb.addKS(ksLoc);
ksIdent = IdentityKS( bb, 'identificationModels/clearthroat_c71f6a3107198299fbd99d42319f54f1' );
ksIdent1 = IdentityKS( bb, 'identificationModels/cough_c71f6a3107198299fbd99d42319f54f1' );
ksIdent2 = IdentityKS( bb, 'identificationModels/doorslam_c71f6a3107198299fbd99d42319f54f1' );
ksIdent3 = IdentityKS( bb, 'identificationModels/drawer_c71f6a3107198299fbd99d42319f54f1' );
ksIdent4 = IdentityKS( bb, 'identificationModels/keyboard_c71f6a3107198299fbd99d42319f54f1' );
ksIdent5 = IdentityKS( bb, 'identificationModels/keys_c71f6a3107198299fbd99d42319f54f1' );
ksIdent6 = IdentityKS( bb, 'identificationModels/knock_c71f6a3107198299fbd99d42319f54f1' );
ksIdent7 = IdentityKS( bb, 'identificationModels/laughter_c71f6a3107198299fbd99d42319f54f1' );
ksIdent8 = IdentityKS( bb, 'identificationModels/mouse_c71f6a3107198299fbd99d42319f54f1' );
ksIdent9 = IdentityKS( bb, 'identificationModels/pageturn_c71f6a3107198299fbd99d42319f54f1' );
ksIdent10 = IdentityKS( bb, 'identificationModels/pendrop_c71f6a3107198299fbd99d42319f54f1' );
ksIdent11 = IdentityKS( bb, 'identificationModels/phone_c71f6a3107198299fbd99d42319f54f1' );
ksIdent12 = IdentityKS( bb, 'identificationModels/speech_c71f6a3107198299fbd99d42319f54f1' );
ksIdent13 = IdentityKS( bb, 'identificationModels/switch_c71f6a3107198299fbd99d42319f54f1' );
bb.addKS( ksIdent );
bb.addKS( ksIdent1 );
bb.addKS( ksIdent2 );
bb.addKS( ksIdent3 );
bb.addKS( ksIdent4 );
bb.addKS( ksIdent5 );
bb.addKS( ksIdent6 );
bb.addKS( ksIdent7 );
bb.addKS( ksIdent8 );
bb.addKS( ksIdent9 );
bb.addKS( ksIdent10 );
bb.addKS( ksIdent11 );
bb.addKS( ksIdent12 );
bb.addKS( ksIdent13 );
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
bm.registerEvent('NewAcousticCues', ksLoc, ksIdent, ksIdent1, ksIdent2, ksIdent3, ksIdent4, ksIdent5, ksIdent6, ksIdent7, ksIdent8, ksIdent9, ksIdent10, ksIdent11, ksIdent12, ksIdent13);
bm.registerEvent('NewLocationHypothesis', ksConf, ksConfSolver);
bm.registerEvent( 'NewIdentityHypothesis' );
bm.registerEvent('NewConfusionHypothesis', ksRotate);

if plotting
%% Add event listeners for plotting
addlistener(bb, 'NewSignalBlock', @plotSignalBlocks);
addlistener(bb, 'NewPeripherySignal', @plotPeripherySignal);
addlistener(bb, 'NewAcousticCues', @plotAcousticCues);
addlistener(bb, 'NewLocationHypothesis', @plotLocationHypothesis);
addlistener(bb, 'NewIdentityHypothesis', @plotIdentityHypothesis);
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

estError = 1 / (length(estLocations) - 1) * sum(abs(estLocations(1:end-1) - ...
    srcPos * ones(bb.getNumPerceivedLocations - 1, 1)));

fprintf('Mean localisation error: %.4f degrees\n', estError);
fprintf('---------------------------------------------------------------------------\n');

fprintf('-------------------- Identity Hypotheses ----------------------------------\n');
fprintf('Block (time)\t\tclass\t\t\t\tdecision value\n');
for n=1:length( bb.identityHypotheses )
    id = bb.identityHypotheses(n);
    shiftDuration = scene.frameShift/simParams.fsHz;
    fprintf( '%d\t(%g-%gs)\t\t%s\t%d\n', id.blockNo, (id.blockNo-1)*shiftDuration, id.blockNo*shiftDuration, id.getIdentityText(), id.decVal );
end
v = load( 'niMixDesc.mat', 'description' );
fis = plotIdentificationScene( 'niMix.wav', v.description, bb.identityHypotheses, scene );
fprintf('---------------------------------------------------------------------------\n');


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

function plotIdentityHypothesis( bb, evnt )
identHyp = bb.identityHypotheses( evnt.data );
disp( identHyp.getIdentityText() );


