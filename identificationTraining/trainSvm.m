function model = trainSvm( tridx, lfolds, dfolds, cvFolds, niState )


disp( '' );
disp( 'grid search for best hyperparameters' );
disp( '' );
if ~isempty(strfind( lower(niState.hyperParamSearch), 'fast' ))
    ridx = tridx(randi( length(tridx) ));
    [~, bk, bg, bc, bcp, vals] = gridSvmTrain( dfolds{ridx}, lfolds{ridx}, cvFolds, niState );
else
    [~, bk, bg, bc, bcp, vals] = gridSvmTrain( vertcat( dfolds{tridx} ), vertcat( lfolds{tridx} ), cvFolds, niState );
end
svmParamString = sprintf( '-t %d -g %e -c %e -w-1 1 -w1 %e -q -e %e', bk, bg, bc, bcp, niState.terminationTolerance );
disp( '' );
disp( 'training with best hyperparameters' );
model = libsvmtrain( vertcat( lfolds{tridx} ), vertcat( dfolds{tridx} ), svmParamString );

