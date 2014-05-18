function [trLabels, trInstances, identities, translators, factors] = createTrainingData( soundsDir, className, checkForPrecomputedData, saveTmpData, niState )

addpath( genpath( getMFilePath() ) );
addpath( genpath( [getMFilePath() '..\..\software\stage1_blackboard_system'] ) );

angles = [0];

[soundFileNames, soundFileNamesOther] = makeSoundLists( soundsDir, className );
soundFileNamesAll = [soundFileNames; soundFileNamesOther];

identities = [];

% for every sound file:
for i = 1:length( soundFileNamesAll )

    disp( ['processing ' soundFileNamesAll{i}] );
    
    % do wp2 processing 
    if checkForPrecomputedData && exist( [soundFileNamesAll{i} '.wp2.mat'], 'file' )
        load( [soundFileNamesAll{i} '.wp2.mat'], 'wp2Features' );
    else
        wp2Features = wp2processSound( soundFileNamesAll{i}, angles, niState );
        if saveTmpData; save( [soundFileNamesAll{i} '.wp2.mat'], 'wp2Features' ); end
    end

    % create labels
    if i < length( soundFileNames )
        labels = makeLabels( soundFileNamesAll{i}, niState, size( wp2Features, 2 ) );
    else
        labels = -1 * ones( size( wp2Features, 2 ), 1 );
    end
    if ~exist( 'trLabels' ); trLabels = labels;
    else trLabels = [trLabels; labels];
    end

    % create features
    instances = makeFeaturesFromWp2Data( wp2Features, niState );    
    if ~exist( 'trInstances' ); trInstances = instances;
    else trInstances = [trInstances; instances];
    end
    
    identities = [identities; repmat( {soundFileNamesAll{i}}, size( wp2Features, 2 ), 1 )];

    disp( '.' );
    
end

[trInstances, translators, factors] = scaleTrainingData( trInstances );

savePreStr = [soundsDir '\' className '\' className '_' niState.strFeatures{:} '_' func2str(niState.featureFunction)];
save( [savePreStr '_data.mat'], 'trInstances', 'trLabels' );
save( [savePreStr '_scale.mat'], 'translators', 'factors' );
dynSaveMFun( @scaleData, [], [savePreStr '_scaleFunction'] );
dynSaveMFun( niState.featureFunction, niState.featureFunctionParam, [savePreStr '_featureFunction'] );

