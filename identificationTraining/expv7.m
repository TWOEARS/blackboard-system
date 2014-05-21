addpath( genpath( getMFilePath() ) );
addpath( genpath( [getMFilePath() '../'] ) );
addpath( genpath( [getMFilePath() '../../tools/'] ) );


ns = makeTrainingState();
ns.hyperParamSearch = 'gridLinear';

produceModel( '../../../testSoundsIEEE_AASP', 'alert', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'clearthroat', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'cough', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'doorslam', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'drawer', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'keyboard', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'keys', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'knock', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'laughter', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'mouse', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'pageturn', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'pendrop', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'phone', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'speech', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'switch', ns );

niState.featureFunction = @polyfeatures;
niState.featureFunctionParam = [];

produceModel( '../../../testSoundsIEEE_AASP', 'alert', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'keys', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'knock', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'laughter', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'speech', ns );

niState.featureFunction = @polyfeatures;
niState.featureFunctionParam = [];
niState.folds = 2;

produceModel( '../../../testSoundsIEEE_AASP', 'alert', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'keys', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'knock', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'laughter', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'speech', ns );

niState.folds = 4;
niState = updateNiStateBlockShiftSize( niState, 20, 2 );

produceModel( '../../../testSoundsIEEE_AASP', 'alert', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'keys', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'knock', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'laughter', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'speech', ns );

niState = updateNiStateBlockShiftSize( niState, 50, 10 );

produceModel( '../../../testSoundsIEEE_AASP', 'alert', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'keys', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'knock', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'laughter', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'speech', ns );

niState = updateNiStateBlockShiftSize( niState, 20, 10 );
niState.angles = [0 60 120 180 240 300];

produceModel( '../../../testSoundsIEEE_AASP', 'alert', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'keys', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'knock', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'laughter', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'speech', ns );

ns.hyperParamSearch = 'grid';

produceModel( '../../../testSoundsIEEE_AASP', 'alert', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'clearthroat', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'cough', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'doorslam', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'drawer', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'keyboard', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'keys', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'knock', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'laughter', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'mouse', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'pageturn', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'pendrop', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'phone', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'speech', ns );
produceModel( '../../../testSoundsIEEE_AASP', 'switch', ns );

