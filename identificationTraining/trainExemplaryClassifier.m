addpath( genpath( getMFilePath() ) );
addpath( genpath( [getMFilePath() '../'] ) );

soundsDir = 'C:/Users/ivot/Projekte/twoEars/testSoundsIEEE_AASP';
className = 'knock';
niState = makeTrainingState();
[l, d, ids, translate, scale] = createTrainingData( soundsDir, className, 1, 1, niState );

[ltr, lte, dtr, dte, idstr, idste] = splitDataPermutation( l, d, ids, 0.75 );

model = trainSvm( ltr, dtr, 5 );
save( [soundsDir '/' className '/' className '_' niState.strFeatures{:} '_' func2str(niState.featureFunction) '_model.mat'], 'model' );

[pl, val] = libsvmPredictExt( lte, dte, model );

if mean(pl) == -1
    disp( 'Produced trivial model.' );
end

desc = makeTestScene( idste, lte, 10 );
