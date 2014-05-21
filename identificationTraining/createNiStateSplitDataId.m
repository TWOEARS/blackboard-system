function id = createNiStateSplitDataId( niState )

id = DataHash( {createNiStateDataId( niState ) niState.folds} );
