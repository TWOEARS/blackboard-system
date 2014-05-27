function id = createNiStateWP2id( niState )

id = DataHash( {niState.simParams.fsHz niState.simParams.nErbs niState.simParams.nChannels niState.simParams.mEarF niState.simParams.fLowHz niState.simParams.fHighHz niState.simParams.ihcMethod niState.simParams.winSizeSec niState.simParams.hopSizeSec niState.simParams.winType niState.simParams.blockSize niState.hopsPerShift niState.strCues niState.strFeatures niState.angles} );
