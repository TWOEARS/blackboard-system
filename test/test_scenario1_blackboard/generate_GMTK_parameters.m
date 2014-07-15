function generate_GMTK_parameters(gmtkEngine, numAngles, featureRange)
%generateInitialParameters Summary of this function goes here
%   Detailed explanation goes here

    if nargin < 3
        % By default, use all the features
        featureRange = [0 gmtkEngine.dimFeatures-1];
    end

    % Calculate the number of features that will be used
    numUsedFeatures = featureRange(2) - featureRange(1) + 1;

    % Generate common parameters used by other files
    generateCommonParams(gmtkEngine.workPath, gmtkEngine.dimFeatures, featureRange, numAngles);

    % Generate master file
    generateMasterParams(gmtkEngine.inputMaster, numAngles);

    % Generate trainable master file
    generateTrainableMasterParams(gmtkEngine.inputMasterTrainable, numUsedFeatures, numAngles);

end

function generateCommonParams(workPath, dimFeatures, featureRange, numAngles)
% Generates common parameters used by all the other files
    outfn = sprintf('%s/commonParams', workPath);
    fid = fopen(outfn, 'w');
    if fid < 0
        error('Cannot open %s', outfn);
    end
    fprintf(fid, '%%\n%% Common definitions for both structural and parameter files\n\n');
    fprintf(fid, '#ifndef COMMON_PARAMS\n');
    fprintf(fid, '#define COMMON_PARAMS\n');
    fprintf(fid, '\n');
    fprintf(fid, '#define OBS_RANGE_FEATURE %d:%d\n', featureRange(1), featureRange(2));
    fprintf(fid, '#define OBS_RANGE_LOCATION %d:%d\n', dimFeatures, dimFeatures);
    fprintf(fid, '#define NUM_LOCATIONS %d\n', numAngles);
    fprintf(fid, '\n');
    fprintf(fid, '#endif\n\n');
    fclose(fid);
end

function generateMasterParams(outfn, numAngles)
% Generate non-trainable paramerters
    fid = fopen(outfn, 'w');
    if fid < 0
        error('Cannot open %s', outfn);
    end
    print_section_title(fid, 'Parameter file');
    fprintf(fid, '\n#include "commonParams"\n\n');
    print_non_trainable_params(fid, numAngles);
    fclose(fid);
end

function generateTrainableMasterParams(outfn, numUsedFeatures, numAngles)
% Generate trainable paramerters
    fid = fopen(outfn, 'w');
    if fid < 0
        error('Cannot open %s', outfn);
    end

    print_section_title(fid, 'Parameter file');
    fprintf(fid, '\n#include "commonParams"\n\n');

    % Print Dense CPTs
    print_section_title(fid, 'CPTs');
    fprintf(fid, 'DENSE_CPT_IN_FILE inline\n');
    fprintf(fid, '1 %% num DenseCPTs\n');

    fprintf(fid, '0 locationCPT %% num, name\n');
    fprintf(fid, '0 %d %% num parents, num values\n', numAngles);
    for n=1:numAngles
        fprintf(fid, '%.8f ', 1/numAngles);
    end
    fprintf(fid, '\n');

    % Print Gaussians
    print_section_title(fid, 'Gaussians');
    fprintf(fid, '%% Discrete PMFs\n');
    fprintf(fid, 'DPMF_IN_FILE inline %d\n', numAngles);
    for n=0:numAngles-1
       fprintf(fid, '%d %% pmf %d\n', n, n);
       fprintf(fid, 'mx%d 1 %% name, cardinality\n', n);
       fprintf(fid, '1.0\n');
    end
    fprintf(fid, '\n');
    fprintf(fid, '%% Means\n');
    fprintf(fid, 'MEAN_IN_FILE inline %d\n', numAngles);
    for n=0:numAngles-1
       fprintf(fid, '%d mean%d %% num, name\n', n, n);
       fprintf(fid, '%d %% dimensionality\n', numUsedFeatures);
       for m=1:numUsedFeatures
        fprintf(fid, '0.0 ');
       end
       fprintf(fid, '\n');
    end
    fprintf(fid, '\n');
    fprintf(fid, '%% Variances\n');
    fprintf(fid, 'COVAR_IN_FILE inline %d\n', numAngles);
    for n=0:numAngles-1
       fprintf(fid, '%d covar%d %% num, name\n', n, n);
       fprintf(fid, '%d %% dimensionality\n', numUsedFeatures);
       for m=1:numUsedFeatures
        fprintf(fid, '0.1 ');
       end
       fprintf(fid, '\n');
    end
    fprintf(fid, '\n');
    fprintf(fid, '%% Gaussian components\n');
    fprintf(fid, 'MC_IN_FILE inline %d\n', numAngles);
    for n=0:numAngles-1
       fprintf(fid, '%d %d 0 gc%d %% num, dim, type, name\n', n, numUsedFeatures, n);
       fprintf(fid, 'mean%d covar%d\n', n, n);
    end
    fprintf(fid, '\n');
    fprintf(fid, '%% Gaussian mixtures\n');
    fprintf(fid, 'MX_IN_FILE inline %d\n', numAngles);
    for n=0:numAngles-1
       fprintf(fid, '%d %d gm%d 1 %% num, dim, name, num comp\n', n, numUsedFeatures, n);
       fprintf(fid, 'mx%d gc%d\n', n, n);
    end
    fprintf(fid, '\n');

    % Print non-trainable params
    print_non_trainable_params(fid, numAngles);
    fclose(fid);
    
end

function print_section_title(fid, txt)
    fprintf(fid, '\n%%-----------------------------------------\n');
    fprintf(fid, '%% %s\n', txt);
    fprintf(fid, '%%-----------------------------------------\n');
end

function print_non_trainable_params(fid, numAngles)
    print_section_title(fid, 'Name collections');
    fprintf(fid, 'NAME_COLLECTION_IN_FILE inline 2\n');
    fprintf(fid, '0 locationTable %% num, name\n');
    fprintf(fid, '%d\n', numAngles);
    loc_step = ceil(360/numAngles);
    for loc=0:loc_step:360-loc_step
       fprintf(fid, '%d ', loc);
    end
    fprintf(fid, '\n');
    fprintf(fid, '1 colObs %% num, name\n');
    fprintf(fid, '%d\n', numAngles);
    for n=0:numAngles-1
       fprintf(fid, 'gm%d ', n);
    end
    fprintf(fid, '\n');
    
    print_section_title(fid, 'Decision trees');
    fprintf(fid, 'DT_IN_FILE inline 1\n');
    fprintf(fid, '0 directMappingWithOneParent %% num, name\n');
    fprintf(fid, '1 %% one parent\n');
    fprintf(fid, '0 1 default\n');
    fprintf(fid, '   -1 {(p0)} %% just copy value of parent\n');
    fprintf(fid, '\n');
end


