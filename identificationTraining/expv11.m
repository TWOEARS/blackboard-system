addpath( genpath( getMFilePath() ) );
addpath( genpath( [getMFilePath() '../'] ) );
addpath( genpath( [getMFilePath() '../../tools/'] ) );


ns = makeTrainingState();
ns.hyperParamSearch = 'fastGridLinear';
ns.simParams.nChannels = 64;
ns = updateNiStateBlockShiftSize( ns, 20, 10 );

produceModel( '../../../testSoundsIEEE_AASP', 'alert', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'clearthroat', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'cough', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'doorslam', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'drawer', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'knock', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'mouse', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'pageturn', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'phone', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'speech', ns );

ns = makeTrainingState();
ns.folds = 4;
ns.hyperParamSearch = 'fastGridRBF';
ns.searchBudget = 25;

produceModel( '../../../testSoundsIEEE_AASP', 'drawer', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'phone', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'speech', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'knock', ns );


