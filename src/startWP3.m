
% This script initialises the path variables that are needed for running
% the WP3 code.

basepath = fileparts(mfilename('fullpath'));

% Add all relevant folders to the matlab search path
addpath(fullfile(basepath, 'blackboard_core'));
addpath(fullfile(basepath, 'blackboard_data'));
addpath(fullfile(basepath, 'evaluation'));
addpath(fullfile(basepath, 'gmtk_matlab_interface'));
addpath(fullfile(basepath, 'identificationTraining'));
addpath(fullfile(basepath, 'knowledge_sources'));

clear basepath;
