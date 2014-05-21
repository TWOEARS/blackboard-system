function [bestVal, bestKernel, bestGamma, bestC, bestCp, vals] = gridSvmTrain( trInstances, trLabels, cvFolds, niState )

lpShare = (mean(trLabels) + 1 ) * 0.5;
cp = (1-lpShare)/lpShare;

kernels = [0 2];
cs = logspace( -4, 4, 9 );
gammas = logspace( -12, 2, 9 );

vals = [];

if strcmpi( niState.hyperParamSearch, 'gridLinear' )
    kernels = 0;
    niState.hyperParamSearch = 'grid';
end

switch( lower( niState.hyperParamSearch ) )
    case 'grid'
        bestVal = 0;
        for kernel = kernels
        for c = cs
        for gamma = gammas
            svmParamString = sprintf( '-t %d -g %e -c %e -w-1 1 -w1 %e -q', kernel, gamma, c, cp );
            disp( ['cv with ' svmParamString] );
            val = libsvmCVext( trLabels, trInstances, svmParamString, cvFolds, bestVal );
            vals = [vals; {kernel, c, gamma, val}];
            if val > bestVal
                bestVal = val;
                bestKernel = kernel;
                bestGamma = gamma;
                bestC = c;
                bestCp = cp;
            end
            if kernel == 0
                break;
            end
        end
        end
        end

    case 'random'
end

%save( [niState.name '_' niState.hyperParamSearch '.mat'], 'vals' );
