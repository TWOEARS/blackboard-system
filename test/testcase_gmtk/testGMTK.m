function testGMTK
%
% The test case is to make sure the gmtk Matlab interface is working.
%
% Ning Ma, 8 July 2014, n.ma@sheffield.ac.uk
%

addpath('../../src/gmtk_matlab_interface');
addpath(genpath(pwd));

%--------------------------------------------------------------------------
% Some global parameters
%--------------------------------------------------------------------------
gmName = 'localisation_static';
locations = 0:5:355;
numLocations = length(locations);
% 32-band ITDs features in total
dimFeatures = 32;
testLoc = 30;

%--------------------------------------------------------------------------
% Initialise GMTK engine
% Default GMTK binary path is:
%    * Linux and Mac OS: '/usr/local/bin'
%    * Windows Cygwin: 'c:\cygwin64\usr\local\bin\'
% If they are located at a different path, you can change the GMTK path by
%    gmtkEngine(gmName, dimFeatures, gmtkPath)
%--------------------------------------------------------------------------
gmtkLoc = gmtkEngine(gmName, dimFeatures);

% Relevant paths
featurePath = fullfile(gmtkLoc.workPath, 'features');
if ~exist(featurePath, 'dir')
    error('Unable to find features in %d', featurePath);
end
featureExt = 'htk';
labelExt = 'lab';
flistPath = fullfile(gmtkLoc.workPath, 'flists');
if ~exist(flistPath, 'dir')
    mkdir(flistPath);
end

%--------------------------------------------------------------------------
% First we need to perform triangulation of graphical models.
% You can find the GM structure files in GM_localisation_static folder:
%     localisation_static_train.str (training GM)
%     localisation_static.str (localisation GM)
% We need to generate some GMTK parameters with generateGMTKParameters.m if 
% this hasn't been done.
%--------------------------------------------------------------------------
fprintf('----------------- Initialising GM parameters\n');
generateGMTKParameters(gmtkLoc, numLocations);
gmtkLoc.triangulate;

%--------------------------------------------------------------------------
% Let's train GM parameters with 4 utterances per location
%--------------------------------------------------------------------------
fprintf('----------------- Training GM parameters\n');
    
% Generate the feature list and the label list
trainFeatureList = fullfile(flistPath, 'train_features.flist');
trainLabelList = fullfile(flistPath, 'train_labels.flist');
fidObsList = fopen(trainFeatureList, 'w');
fidLabList = fopen(trainLabelList, 'w');
for n=1:numLocations
    for m=1:4
        fn = fullfile(featurePath, sprintf('static_azimuth%d_%d', locations(n), m));
        fprintf(fidObsList, '%s.%s\n', fn, featureExt);
        fprintf(fidLabList, '%s.%s\n', fn, labelExt);
    end
end
fclose(fidObsList);
fclose(fidLabList);
    
% Perform training with the feature/label lists
gmtkLoc.train(trainFeatureList, trainLabelList);


%--------------------------------------------------------------------------
% Calculate posteriors given new features at each azimuth location
%--------------------------------------------------------------------------
fprintf('----------------- Calculating posteriros\n');

% Generate test feature list
featureList = fullfile(flistPath, 'test_features.flist');
fprintf('\n---- Calculating posteriors given features at %d degrees\n', testLoc);
fidObsList = fopen(featureList, 'w');
fprintf(fidObsList, '%s/static_azimuth%d_5.htk\n', featurePath, testLoc);
fclose(fidObsList);

% Calculate posteriors of clique 0 (which contains RV:location)
gmtkLoc.infer(featureList, 0);

% Now if successful, posteriors are written in output files with an
% appendix of _0 for the first utterance, _1 for the second and so on.
% Load posteriors when there is no head turn
post = load(strcat(gmtkLoc.outputCliqueFile, '_0'));
meanPost = mean(post,1);

% Plot the results
bar(locations, meanPost, 'FaceColor',[.5 .8 .5]);
set(gca,'XTick', 0:30:359, 'XTickLabel', 0:30:359, 'FontSize', 14);
axis([-5 360 0 1.05]);
xlabel('Azimuth (degrees)', 'FontSize', 16);
ylabel('Probability', 'FontSize', 16);
title(sprintf('Posterior distributions for a source located at %d degrees', testLoc), 'FontSize', 16);


