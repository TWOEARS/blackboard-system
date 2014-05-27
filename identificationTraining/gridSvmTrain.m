function [bestVal, bestKernel, bestGamma, bestC, bestCp, vals] = gridSvmTrain( trInstances, trLabels, cvFolds, niState )

lpShare = (mean(trLabels) + 1 ) * 0.5;
cp = (1-lpShare)/lpShare;

kernels = [2];
cs = logspace( -4, 4, 5 );
gammas = logspace( -12, 2, 5 );

vals = [];

if ~isempty(strfind( lower(niState.hyperParamSearch), 'linear' ))
    kernels = 0;
    cs = logspace( -4, 4, 9 );
end

if ~isempty(strfind( lower(niState.hyperParamSearch), 'grid' ))
    bestVal = 0;
    for kernel = kernels
    for c = cs
    for gamma = gammas
        svmParamString = sprintf( '-t %d -g %e -c %e -w-1 1 -w1 %e -q -e %e', kernel, gamma, c, cp, niState.terminationTolerance );
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
end

if ~isempty(strfind( lower(niState.hyperParamSearch), 'random' ))
    for i = 1:niState.searchBudget
        bestVal = 0;
        kernel = kernels(randi( length(kernels) ));
        c = 10^( log10(cs(1)) + ( log10(cs(end)) - log10(cs(1)) ) * rand( 'double' ) );
        gamma = 10^( log10(gammas(1)) + ( log10(gammas(end)) - log10(gammas(1)) ) * rand( 'double' ) );
        svmParamString = sprintf( '-t %d -g %e -c %e -w-1 1 -w1 %e -q -e %e', kernel, gamma, c, cp, niState.terminationTolerance );
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
    end
end

%save( [niState.name '_' niState.hyperParamSearch '.mat'], 'vals' );
