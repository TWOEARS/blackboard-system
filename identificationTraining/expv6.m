addpath( genpath( getMFilePath() ) );
addpath( genpath( [getMFilePath() '../'] ) );
addpath( genpath( [getMFilePath() '../../tools/'] ) );

ns = makeTrainingState();

ns.angles = [0];

ns.featureFunction = @polyFeatures;

ns.name = 'v3';

produceModel( '../../../testSoundsIEEE_AASP', 'alert', ns );
