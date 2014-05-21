function id = createNiStateModelId( niState )

id = DataHash( {createNiStateSplitDataId( niState ) niState.hyperParamSearch} );
