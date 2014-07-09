% This script initialises the path variables that are needed for running
% the WP3 code.

basepath = fileparts(fileparts(fileparts(mfilename('fullpath'))));

% Add all relevant folders to the matlab search path
addpath(fullfile(basepath, 'twoears-data/sound_databases'));

addpath(fullfile(basepath, 'twoears-wp1/src'));
startWP1;

addpath(fullfile(basepath, 'twoears-wp2/src'));
startWP2;

addpath(fullfile(basepath, 'twoears-wp3/src'));
startWP3;
