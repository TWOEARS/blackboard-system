function sim_stage1

clc;
%clearAllButBreakpoints;
%% Add relevant paths
addpath('blackboard');
addpath('gmtk');
addpath('tools');
addpath(genpath('simulator'));
addpath(genpath('wp2sub'));

plotting = 1;

%% Initialize simulation

% Name of the graphical model
gmName = 'stage1';

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

wavfn = '../dataGit/sound_databases/grid_subset/test/s1/lbayzp.wav';
%wavfn = '../dataGit/sound_databases/IEEE_AASP/test/compilations/test1.wav';

% Initialize scene to be simulated.
%src = SoundSource('Speech', wavfn, 'Polar', [1, srcPos]);
src = SoundSource('EventMix', wavfn, 'Polar', [1, srcPos]);
% Define dummy head
dummyHead = Head('QU_KEMAR_anechoic_3m.mat', simParams.fsHz);
% Create scene
scene = Scene(src.numSamples/src.fs, simParams.fsHz, simParams.blockSize * simParams.fsHz, ...
    simParams.blockSize * simParams.fsHz, dummyHead, [], src);
     
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
hash1 = '00c0c356871969599a0c45266e82e1ec';
hash2 = 'c1703fe8c21b3dfef9c29630a4262c79';
ksIdent   = IdentityKS( bb, 'clearthroat', hash1 );
ksIdent1  = IdentityKS( bb, 'cough',       hash2 );
ksIdent2  = IdentityKS( bb, 'doorslam',    hash1 );
ksIdent3  = IdentityKS( bb, 'drawer',      hash2 );
ksIdent4  = IdentityKS( bb, 'keyboard',    hash2 );
ksIdent5  = IdentityKS( bb, 'keys',        hash2 );
ksIdent6  = IdentityKS( bb, 'knock',       hash1 );
ksIdent7  = IdentityKS( bb, 'laughter',    hash1 );
ksIdent8  = IdentityKS( bb, 'mouse',       hash1 );
ksIdent9  = IdentityKS( bb, 'pageturn',    hash2 );
ksIdent10 = IdentityKS( bb, 'pendrop',     hash2 );
ksIdent11 = IdentityKS( bb, 'phone',       hash2 );
ksIdent12 = IdentityKS( bb, 'speech',      hash2 );
ksIdent13 = IdentityKS( bb, 'switch',      hash2 );
ksIdent14 = IdentityKS( bb, 'alert',       hash2 );
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
bb.addKS( ksIdent14 );
ksConf = ConfusionKS(bb);
bb.addKS(ksConf);
ksConfSolver = ConfusionSolvingKS(bb);
bb.addKS(ksConfSolver);
ksRotate = RotationKS(bb);%, simParams.headRotateAngle);
bb.addKS(ksRotate);

% Register events with a list of KSs that should be triggered
bm = BlackboardMonitor(bb);
bm.registerEvent('ReadyForNextBlock', ksSignalBlock);
bm.registerEvent('NewSignalBlock', ksPeriphery);
bm.registerEvent('NewPeripherySignal', ksAcousticCues);
bm.registerEvent('NewAcousticCues', ksLoc, ksIdent, ksIdent1, ksIdent2, ksIdent3, ksIdent4, ksIdent5, ksIdent6, ksIdent7, ksIdent8, ksIdent9, ksIdent10, ksIdent11, ksIdent12, ksIdent13, ksIdent14);
bm.registerEvent('NewLocationHypothesis', ksConf, ksConfSolver);
bm.registerEvent( 'NewIdentityHypothesis' );
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

v = load( '../dataGit/sound_databases/IEEE_AASP/test/compilations/test1.mat', 'description' );
fprintf('-------------------- Identity Hypotheses ----------------------------------\n');
fprintf('Block (time)\t\tclass\t\t\t\tdecision value\n');
for n=1:length( bb.identityHypotheses )
    id = bb.identityHypotheses(n);
    shiftDuration = scene.frameShift/simParams.fsHz;
    className = id.getIdentityText();
    blockStart = (id.blockNo-1)*shiftDuration;
    blockEnd = id.blockNo*shiftDuration;
    c = 'Errors';
    for i=1:size(v.description, 1)
        if strcmpi( className, v.description{i,2} )  && v.description{i,3} < blockStart  &&  blockStart < v.description{i,4}
            c = '*Green';
        end
        if strcmpi( className, v.description{i,2} )  && v.description{i,3} < blockStart  &&  blockEnd < v.description{i,4}
            c = '*Green';
        end
        if strcmpi( className, v.description{i,2} )  && v.description{i,3} < blockEnd  &&  blockEnd < v.description{i,4}
            c = '*Green';
        end
        if strcmpi( className, v.description{i,2} )  && v.description{i,3} > blockStart  &&  blockEnd > v.description{i,3}
            c = '*Green';
        end
        if strcmpi( className, v.description{i,2} )  && v.description{i,3} > blockStart  &&  blockEnd > v.description{i,4}
            c = '*Green';
        end
        if strcmpi( className, v.description{i,2} )  && v.description{i,4} > blockStart  &&  blockEnd > v.description{i,4}
            c = '*Green';
        end
    end
    cprintf( c, '%d\t(%g-%gs)\t\t%s\t%d\n', id.blockNo, blockStart, blockEnd, className, id.decVal );
end
%fis = plotIdentificationScene( '../dataGit/sound_databases/IEEE_AASP/test/compilations/test1.wav', v.description, bb.identityHypotheses, scene );
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


