function niState = updateNiStateBlockShiftSize( niState, hopsPerBlock, hopsPerShift )

niState.hopsPerBlock = hopsPerBlock;
niState.hopsPerShift = hopsPerShift;
niState.simParams.blockSize = hopsPerBlock * niState.simParams.hopSizeSec;
niState.samplesPerBlock = niState.simParams.fsHz * niState.simParams.blockSize;
niState.shiftSize = hopsPerShift * niState.simParams.hopSizeSec;
niState.samplesPerShift = niState.simParams.fsHz * niState.shiftSize;

niState.wp2states = init_WP2( niState.strFeatures, niState.strCues, niState.simParams );
