function model = trainSvm( ltr, dtr, cvFolds )
    
[~, bk, bg, bc, bcn, bcp] = gridSvmTrain( dtr, ltr, cvFolds );
svmParamString = sprintf( '-t %d -g %e -c %e -w-1 %e -w1 %e -q', bk, bg, bc, bcn, bcp );
model = libsvmtrain( ltr, dtr, svmParamString );

