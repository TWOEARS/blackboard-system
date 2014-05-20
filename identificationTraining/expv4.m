addpath( genpath( getMFilePath() ) );
addpath( genpath( [getMFilePath() '../'] ) );
addpath( genpath( [getMFilePath() '../../tools/'] ) );


ns = makeTrainingState();

ns.angles = [0];

ns.featureFunction = @msFeatures;
ns.featureFunctionParam.derivations = 1;

ns.name = 'v1';

produceModel( '../../../testSoundsIEEE_AASP', 'alert', ns );
