function produceModel( soundsDir, className, niState )

[l, d, ids, ~, ~] = createTrainingData( soundsDir, className, 1, 1, niState );

[ltr, lte, dtr, dte, idstr, idste] = splitDataPermutation( l, d, ids, 0.75 );

model = trainSvm( ltr, dtr, 5 );

savePreStr = [soundsDir '\' className '\' className '_' niState.name '_' niState.strFeatures{:} '_' func2str(niState.featureFunction)];
save( [savePreStr '_model.mat'], 'model', 'val' );

[pl, val] = libsvmPredictExt( lte, dte, model );

if mean(pl) == -1
    disp( 'Produced trivial model.' );
end

save( [savePreStr '_splitdata.mat'], 'ltr', 'lte', 'dtr', 'dte', 'idstr', 'idste' );

save( [savePreStr '_niState.mat'], 'niState' );

