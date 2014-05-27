function produceModel( soundsDir, className, niState )

savePreStr = [soundsDir '/' className '/' className '_' createNiStateModelId(niState)];
delete( [savePreStr '.log'] );
diary( [savePreStr '.log'] );
disp('--------------------------------------------------------');
disp('--------------------------------------------------------');
fn_structdisp( niState )
disp('--------------------------------------------------------');

[l, d, ids, ~, ~] = createTrainingData( soundsDir, className, 1, 1, niState );

[lfolds, dfolds, idsfolds] = splitDataPermutation( l, d, ids, niState.folds );

savePreStr = [soundsDir '/' className '/' className '_' createNiStateSplitDataId(niState)];
save( [savePreStr '_splitdata.mat'], 'lfolds', 'dfolds', 'idsfolds', 'niState' );

for i = 1:niState.folds
    tridx = 1:niState.folds;
    tridx(i) = [];
    
    fprintf( '\n%i. run of generalization assessment CV\ntraining\n', i );

    model = trainSvm( tridx, lfolds, dfolds, 5, niState );
    
    fprintf( '\n%i. run of generalization assessment CV\ntesting\n', i );

    [pl, ~, dec] = libsvmPredictExt( lfolds{i}, dfolds{i}, model );
    
    if model.Label(1) < 0;
        dec = dec * -1;
    end
    val(i) = validation_function( dec, lfolds{i} );
end
genVal = mean( val );
genValStd = std( val );
fprintf( '\nGeneralization perfomance as evaluated by %i-fold CV is %g +-%g\n\n', niState.folds, genVal, genValStd );

disp( 'training model on whole dataset' );
model = trainSvm( 1:niState.folds, lfolds, dfolds, 5, niState );
fprintf( '\nPerfomance on whole dataset:' );
[~, val, ~] = libsvmPredictExt( vertcat( lfolds{:} ), vertcat( dfolds{:} ), model );

savePreStr = [soundsDir '/' className '/' className '_' createNiStateModelId(niState)];
save( [savePreStr '_model.mat'], 'model', 'val', 'genVal', 'genValStd', 'niState' );

diary off;