function train_GM(updateGM, genData)
% GM training script using the Graphical Model Toolkit (GMTK)
%
% Sound sources are positioned in the horizontal plane in the range of 0 
% ... 355 degrees, with an angular resolution of 5 degrees (0:5:355).
%
% Localisation is performed using a static Bayesian network, which is 
% trained on ITDs and ILDs extracted from 32-band binaural data.
%
% GMTK binaries are needed for this demo, defined in "gmtkPath".
%
% train_GM           - Simply compute posteriors for each azimuth angle
%
% train_GM(1)        - Update GM parameters first then perform inference.
%                      Needed if new training data are used
%
% train_GM(1, 1)     - Generate spatial training data first
%
% Ning Ma, 10 March 2014, n.ma@sheffield.ac.uk
%

addpath(genpath(pwd));

if nargin < 1
    updateGM = 1;
end
if nargin < 2
    genData = 0;
end

%--------------------------------------------------------------------------
% Some global parameters
%--------------------------------------------------------------------------
gmName = 'stage1';

% Define angular resolution
angularResolution = 5;
numAngles = 360 / angularResolution;
angles = linspace(0, 360 - angularResolution, numAngles);

% 32-band ITDs and 32-band ILDs
dimFeatures = 62;

% Training data duration in seconds
trainDurationSec = 3;

%--------------------------------------------------------------------------
% Initialise GMTK engine
%--------------------------------------------------------------------------
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

%--------------------------------------------------------------------------
% Now need to manually create GM structure files (.str). This could be 
% automated in the future if necessary. Also need to generate relevant GMTK 
% parameters, either manually or with generateGMTKParameters. Finally let's
% perform triangulation.
%--------------------------------------------------------------------------
if updateGM
    fprintf('----------------- Initialising GM parameters\n');
    generateGMTKParameters(gmtkLoc, numAngles);
    gmtkLoc.triangulate;
end

%--------------------------------------------------------------------------
% Generate training data for each azimuth angle
%--------------------------------------------------------------------------
if genData
    fprintf('----------------- Generating training data\n');
    generateTrainingData(dataPath, angles, trainDurationSec);
end

%--------------------------------------------------------------------------
% Estimate GM parameters
%--------------------------------------------------------------------------
numTrainingBlocks = 5;
if updateGM
    fprintf('----------------- Estimating GM parameters\n');
    % Generate feature list and label list
    trainFeatureList = fullfile(flistPath, 'train_features.flist');
    trainLabelList = fullfile(flistPath, 'train_labels.flist');
    fidObsList = fopen(trainFeatureList, 'w');
    fidLabList = fopen(trainLabelList, 'w');
    for n=1:numAngles
        for b = 1:numTrainingBlocks
            fn = fullfile(dataPath, sprintf('spatial_cues_location%d_block%d', n-1, b));
            fprintf(fidObsList, '%s.%s\n', fn, featureExt);
            fprintf(fidLabList, '%s.%s\n', fn, labelExt);
        end
    end
    fclose(fidObsList);
    fclose(fidLabList);
    gmtkLoc.train(trainFeatureList, trainLabelList);
end

%--------------------------------------------------------------------------
% Calculate posteriors of new spatial cues for each azimuth angle
%--------------------------------------------------------------------------
fprintf('----------------- Calculating posteriros\n');
featureList = fullfile(flistPath, 'test_features.flist');
meanPosts = zeros(numAngles, numAngles);
for n=1:numAngles
    % Generate test feature list
    testAngle = angles(n);
    fprintf('\n---- Calculating posteriors given features at %d degrees\n', testAngle);
    fidObsList = fopen(featureList, 'w');
    fn = fullfile(dataPath, sprintf('spatial_cues_location%d_block%d', n-1, numTrainingBlocks+1));
    fprintf(fidObsList, '%s.%s\n', fn, featureExt);
    fclose(fidObsList);
    
    % Calculate posteriors of clique 0 (which contains RV:location)
    gmtkLoc.infer(featureList, 0);
    
    % Now if successful, posteriors are written in output files with an
    % appendix of _0 for the first utterance, _1 for the second and so on.
    % Load posteriors when there is no head turn
    post = load(strcat(gmtkLoc.outputCliqueFile, '_0'));
    meanPosts(n,:) = mean(post,1);
end
mesh(meanPosts);

%     % Plotting results
%     subplot(4,3,n)
%     bar(meanPost');
%     set(gca,'XTickLabel', locations, 'FontSize', 14);
%     if n > 9
%         xlabel('Azimuth (degrees)', 'FontSize', 16);
%     end
%     if n==3
%         h = legend('No head turn', '30 degree right turn');
%         set(h, 'FontSize', 16);
%     end
%     ylabel('Mean posteriors', 'FontSize', 16);
%     axis([0 numAngles+1 0 1.2]);
%     title(sprintf('Sound located at %d degrees', testAngle), 'FontSize', 16);
%colormap(summer)

