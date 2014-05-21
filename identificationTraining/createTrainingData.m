function [trLabels, trInstances, identities, translators, factors] = createTrainingData( soundsDir, className, checkForPrecomputedData, saveTmpData, niState )

[soundFileNames, soundFileNamesOther] = makeSoundLists( soundsDir, className );
soundFileNamesAll = [soundFileNames; soundFileNamesOther];

identities = [];

% for every sound file:
for i = 1:length( soundFileNamesAll )

    disp( ['processing ' soundFileNamesAll{i}] );
    
    % do wp2 processing 
    soundwp2mat = [soundFileNamesAll{i} '.' createNiStateWP2id(niState) '.wp2.mat'];
    if checkForPrecomputedData && exist( soundwp2mat, 'file' )
        load( soundwp2mat, 'wp2Features' );
    else
        wp2Features = wp2processSound( soundFileNamesAll{i}, niState );
        if saveTmpData; save( soundwp2mat, 'wp2Features', 'niState' ); end
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

savePreStr = [soundsDir '/' className '/' className '_' createNiStateDataId(niState)];
save( [savePreStr '_data.mat'], 'trInstances', 'trLabels', 'identities', 'niState' );
save( [savePreStr '_scale.mat'], 'translators', 'factors', 'niState' );
dynSaveMFun( @scaleData, [], [savePreStr '_scaleFunction'] );
dynSaveMFun( niState.featureFunction, niState.featureFunctionParam, [savePreStr '_featureFunction'] );

