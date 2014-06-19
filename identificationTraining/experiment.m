%% add needed pathes

addpath( genpath( getMFilePath() ) );
addpath( genpath( [getMFilePath() '../'] ) );
addpath( genpath( [getMFilePath() '../../tools/'] ) );

%% create experiment: standard

e1setup = setupExperiment();
%% produce models for experiment

%produceModel( '../../../testSoundsIEEE_AASP', 'alert', e1setup );
%produceModel( '../../../testSoundsIEEE_AASP', 'clearthroat', e1setup );
produceModel( '../../../testSoundsIEEE_AASP', 'cough', e1setup );
produceModel( '../../../testSoundsIEEE_AASP', 'doorslam', e1setup );
produceModel( '../../../testSoundsIEEE_AASP', 'drawer', e1setup );
produceModel( '../../../testSoundsIEEE_AASP', 'keyboard', e1setup );
produceModel( '../../../testSoundsIEEE_AASP', 'keys', e1setup );
%produceModel( '../../../testSoundsIEEE_AASP', 'knock', e1setup );
produceModel( '../../../testSoundsIEEE_AASP', 'laughter', e1setup );
produceModel( '../../../testSoundsIEEE_AASP', 'mouse', e1setup );
produceModel( '../../../testSoundsIEEE_AASP', 'pageturn', e1setup );
produceModel( '../../../testSoundsIEEE_AASP', 'pendrop', e1setup );
produceModel( '../../../testSoundsIEEE_AASP', 'phone', e1setup );
produceModel( '../../../testSoundsIEEE_AASP', 'speech', e1setup );
produceModel( '../../../testSoundsIEEE_AASP', 'switch', e1setup );


%% put together perfomance numbers of experiments for comparison

[ted, tv, tev] = makeResultsTable( '../../../testSoundsIEEE_AASP', e1setup );
disp( tev );
