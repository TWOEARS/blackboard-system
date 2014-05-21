function model = trainSvm( ltr, dtr, cvFolds, niState )

disp( '' );
disp( 'grid search for best hyperparameters' );
disp( '' );
[~, bk, bg, bc, bcp, vals] = gridSvmTrain( dtr, ltr, cvFolds, niState );
svmParamString = sprintf( '-t %d -g %e -c %e -w-1 1 -w1 %e -q', bk, bg, bc, bcp );
disp( '' );
disp( 'training with best hyperparameters' );
model = libsvmtrain( ltr, dtr, svmParamString );

