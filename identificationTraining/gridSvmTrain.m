function [bestVal, bestKernel, bestGamma, bestC, bestCn, bestCp] = gridSvmTrain( trInstances, trLabels, cvFolds )

lpShare = (mean(trLabels) + 1 ) * 0.5;

bestVal = 0;
for kernel = [0]
for c = logspace( -4, 3, 7 )
for cn = [1]
for cp = [0.66*(1-lpShare)/lpShare, (1-lpShare)/lpShare, 1.5*(1-lpShare)/lpShare]
for gamma = logspace( -12, 2, 10 )
    svmParamString = sprintf( '-t %d -g %e -c %e -w-1 %e -w1 %e -q', kernel, gamma, c, cn, cp);
    disp( ['cv with ' svmParamString] );
    val = libsvmCVext( trLabels, trInstances, svmParamString, cvFolds, bestVal );
    if val > bestVal
        bestVal = val;
        bestKernel = kernel;
        bestGamma = gamma;
        bestC = c;
        bestCn = cn;
        bestCp = cp;
    end
    if kernel == 0
        break;
    end
end
end
end
end
end
