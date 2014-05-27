function niState = makeTrainingState()

niState.simParams = initSimulationParameters('ident');
niState.strCues = { };
niState.strFeatures = { 'ratemap_feature1' };

niState.winSamples = 2 * round(niState.simParams.winSizeSec * niState.simParams.fsHz / 2);
niState.hopSamples = 2 * round(niState.simParams.hopSizeSec * niState.simParams.fsHz / 2);

niState = updateNiStateBlockShiftSize( niState, 20, 10 );

niState.angles = [0];

niState.featureFunction = @msFeatures;
niState.featureFunctionParam.derivations = 1;

niState.terminationTolerance = 0.001;
niState.hyperParamSearch = 'grid';
niState.searchBudget = 9;
niState.folds = 4;