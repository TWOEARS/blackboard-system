function generate_training_data(dataPath, angles, nChannels)
%
%  dataPath              Path for saving training data
%  angles                All angles used in training
%  nChannels             The number of filter channels
%


%% Add relevant paths
%
import simulator.*
import xml.*


%% Initialise simulation
%
% Distance of speech source (related to the HRTF catalog)
distSource = 3;

% Sampling frequency
fsHz = 44.1E3;

% SourceBuffer with file
sourceBuffer = buffer.FIFO();

% Speech source
source = AudioSource(...          % define AudioSource with ...
    AudioSourceType.POINT, ...    % Point Source Type
    sourceBuffer);                % Buffer as signal source

% Sinks/Head
head = AudioSink(2);
head.set('Position',  [0; 0; 1.75]);  
head.set('UnitFront', [1; 0; 0]); % head is looking to positive x

% HRIRs
hrir = DirectionalIR(xml.dbGetFile('impulse_responses/qu_kemar_anechoic/QU_KEMAR_anechoic_3m.wav'));  

% Simulator
sim = SimulatorConvexRoom();  % simulator object

sim.set(...
    'SampleRate', fsHz, ...         % sampling frequency
    'BlockSize', 2^12, ...          % blocksize
    'NumberOfThreads', 1, ...       % number of threads
    'MaximumDelay', 0.0, ...        % maximum distance delay in seconds
    'Renderer', @ssr_binaural, ...  % SSR rendering function (do not change this!)
    'HRIRDataset', hrir, ...        % assign HRIR-Object to Simulator
    'Sources', source, ...          % assign sources to Simulator
    'Sinks', head);                 % assign sinks to Simulator

sim.set('Init',true);


%% Initialise all WP2 related parameters
%
% Framing parameters
blockSec = 20E-3;
stepSec  = 10E-3;

% Gammatone parameters
f_low       = 80;
f_high      = 8000;
rm_decaySec = 0;

% Request cues being extracted
WP2_requests = {'ild' 'itd_xcorr'};

% Frequency range and number of channels
WP2_param = genParStruct('f_low',f_low,'f_high',f_high,...
                         'nChannels',nChannels,...
                         'rm_decaySec',rm_decaySec,...
                         'ild_wSizeSec',blockSec,...
                         'ild_hSizeSec',stepSec,'rm_wSizeSec',blockSec,...
                         'rm_hSizeSec',stepSec,'cc_wSizeSec',blockSec,...
                         'cc_hSizeSec',stepSec);                 

% Create an empty data object. It will be filled up as new ear signal
% chunks are "acquired". 


%% Read training data
%
trainfn = fullfile(xml.dbPath, 'sound_databases/grid_subset/training/training.wav'); 
[train_signal,fsHz_train] = audioread(trainfn);
% Use 5 seconds for training
train_seconds = 5;
train_signal = train_signal(1:(fsHz_train*train_seconds));
% Upsample speech if required
if fsHz_train ~= fsHz
    train_signal = resample(train_signal, fsHz, fsHz_train);
end


%% Generate binaural cues
%
clc;
numAngles = length(angles);
for n = 1 : numAngles
    
    tic;
    fprintf('---- Generating acoustic cues at %d degrees\n', angles(n));
    
    % Set source azimuth
    srcPosition = distSource * [cosd(angles(n)); sind(angles(n)); 0];
    source.set('Position', srcPosition);
    % Use 'ReInit' before setting the new speech file
    sim.set('ReInit',true);
    
    % Fill speech buffer
    sourceBuffer.setData(train_signal);
    
    % Get spatialised signals
    sig = double(sim.getSignal(train_seconds));
    
    % Compute binaural cues
    dObj = dataObject(sig, fsHz);
    mObj = manager(dObj, WP2_requests, WP2_param);   % Instantiate a manager
    mObj.processSignal();
    
    % Save binaural cues
    itd = dObj.itd_xcorr{1}.Data' .* 1000; % convert to ms
    ild = dObj.ild{1}.Data';
    
    fn = fullfile(dataPath, sprintf('spatial_cues_angle%d', angles(n)));
    writehtk(strcat(fn, '.htk'), [itd; ild]);
    
    % Save labels for each frame
    fid = fopen(strcat(fn, '.lab'), 'w');
    fprintf(fid, '%d\n', repmat(n-1,1,size(itd,2)));
    fclose(fid);
    
    clc;
    toc;
    fprintf('\n');
end

%% clean up
%
sim.set('ShutDown',true);









