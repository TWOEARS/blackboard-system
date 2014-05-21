function id = createNiStateDataId( niState )

id = DataHash( {createNiStateWP2id( niState ) niState.featureFunction niState.featureFunctionParam} );
