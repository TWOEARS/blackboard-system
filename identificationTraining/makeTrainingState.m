function niState = makeTrainingState()

niState.simParams = initSimulationParameters('ident');
niState.winSamples = 2 * round(niState.simParams.winSizeSec * niState.simParams.fsHz / 2);
niState.hopSamples = 2 * round(niState.simParams.hopSizeSec * niState.simParams.fsHz / 2);
%niState.framesPerBlock = floor( (niState.samplesPerBlock - (niState.winSamples-niState.hopSamples)) / niState.hopSamples );
niState.hopsPerBlock = 20; %make frames*fsHz*hopSize dividable by 2
niState.simParams.blockSize = niState.hopsPerBlock * niState.simParams.hopSizeSec;
niState.samplesPerBlock = niState.simParams.fsHz * niState.simParams.blockSize;
niState.hopsPerShift = 10; %make frames*fsHz*hopSize dividable by 2
niState.shiftSize = niState.hopsPerShift * niState.simParams.hopSizeSec;
niState.samplesPerShift = niState.simParams.fsHz * niState.shiftSize;
niState.strCues = { };
niState.strFeatures = { 'ratemap_feature1' };
niState.wp2states = init_WP2( niState.strFeatures, niState.strCues, niState.simParams );
niState.featureFunction = @msFeatures;
niState.featureFunctionParam.derivations = 1;