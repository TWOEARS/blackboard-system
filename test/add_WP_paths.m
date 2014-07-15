function add_WP_paths
%
% This script initialises the path variables that are needed for running
% the WP3 testing code.

reporoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));

% Add all relevant folders to the matlab search path
addpath(fullfile(reporoot, 'twoears-wp1/src'));
startWP1;

addpath(genpath(fullfile(reporoot, 'twoears-wp2/src')));

addpath(genpath(fullfile(reporoot, 'twoears-wp3/src')));
