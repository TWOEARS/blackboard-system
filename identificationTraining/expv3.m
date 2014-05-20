addpath( genpath( getMFilePath() ) );
addpath( genpath( [getMFilePath() '../'] ) );
addpath( genpath( [getMFilePath() '../../tools/'] ) );

ns = makeTrainingState();

ns.angles = [0];

ns.featureFunction = @polyFeatures;
ns.featureFunctionParam.derivations = 1;

ns.name = 'v3';

produceModel( '../../../testSoundsIEEE_AASP', 'knock', ns );
