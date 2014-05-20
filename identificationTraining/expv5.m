addpath( genpath( getMFilePath() ) );
addpath( genpath( [getMFilePath() '../'] ) );
addpath( genpath( [getMFilePath() '../../tools/'] ) );

ns = makeTrainingState();

ns.angles = [0 45 90 135 180 225 270 315];

ns.featureFunction = @msFeatures;
ns.featureFunctionParam.derivations = 1;

ns.name = 'v2';

produceModel( '../../../testSoundsIEEE_AASP', 'alert', ns );
