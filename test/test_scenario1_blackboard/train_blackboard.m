function train_blackboard(genData)
% Training script using the Graphical Model Toolkit (GMTK)
%
% Sound sources are positioned in the horizontal plane in the range of 0 
% ... 355 degrees, with an angular resolution of 5 degrees (0:5:355).
%
% Localisation is performed using a static Bayesian network, which is 
% trained on ITDs and ILDs extracted from 32-band binaural data.
%
%   genData           - If 1 (default), generate training data first
%
% Ning Ma, 10 March 2014, n.ma@sheffield.ac.uk
%

addpath('..');
add_WP_paths;

if nargin < 1
    genData = 1;
end


%% Define training parameters
%
gmName = 'scenario1';

% Define angular resolution
angularResolution = 5;

% All possible azimuth angles
angles = 0:angularResolution:(360-angularResolution);
numAngles = length(angles);

% 32-band ITDs and 32-band ILDs
nChannels = 32;
dimFeatures = nChannels * 2;


%% Initialise GMTK engine
%
gmtkLoc = gmtkEngine(gmName, dimFeatures);

% Relevant paths
dataPath = fullfile(gmtkLoc.workPath, 'data');
if ~exist(dataPath, 'dir')
    mkdir(dataPath);
end
featureExt = 'htk';
labelExt = 'lab';
flistPath = fullfile(gmtkLoc.workPath, 'flists');
if ~exist(flistPath, 'dir')
    mkdir(flistPath);
end


%% Generate training data for each azimuth angle
%
if genData
    fprintf('----------------- Generating training data\n');
    generate_training_data(dataPath, angles, nChannels);
end


%% Generate GMTK parameters
% Now need to create GM structure files (.str) and generate relevant GMTK 
% parameters, either manually or with generateGMTKParameters.
% Finally, perform model triangulation.
%
fprintf('----------------- Initialising GM parameters\n');
generate_GMTK_parameters(gmtkLoc, numAngles);
gmtkLoc.triangulate;


%% Estimate GM parameters
%
fprintf('----------------- Estimating GM parameters\n');
% Generate feature list and label list
trainFeatureList = fullfile(flistPath, 'train_features.flist');
trainLabelList = fullfile(flistPath, 'train_labels.flist');
fidObsList = fopen(trainFeatureList, 'w');
fidLabList = fopen(trainLabelList, 'w');
for n=1:numAngles
    fn = fullfile(dataPath, sprintf('spatial_cues_angle%d', angles(n)));
    fprintf(fidObsList, '%s.%s\n', fn, featureExt);
    fprintf(fidLabList, '%s.%s\n', fn, labelExt);
end
fclose(fidObsList);
fclose(fidLabList);
gmtkLoc.train(trainFeatureList, trainLabelList);


