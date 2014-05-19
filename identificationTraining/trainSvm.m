function model = trainSvm( ltr, dtr, cvFolds, niState )
    
[~, bk, bg, bc, bcp, vals] = gridSvmTrain( dtr, ltr, cvFolds, niState );
svmParamString = sprintf( '-t %d -g %e -c %e -w-1 1 -w1 %e -q', bk, bg, bc, bcp );
model = libsvmtrain( ltr, dtr, svmParamString );

