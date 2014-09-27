classdef IdentityKS < Wp2DepKS
    
    properties (SetAccess = private)
        modelname;
        model;                 % classifier model
        featureFunc;
        featureParam;
        scaleFunc;
        scale;
        tmpFuncs;
    end

    methods
        function obj = IdentityKS( modelName, modelVersion )
            modelFileName = [modelName '_' modelVersion];
            v = load( [modelFileName '_model.mat'] );
            wp2requests.r = v.esetup.wp2dataCreation.requests;
            wp2requests.p = v.esetup.wp2dataCreation.requestP;
            wp2requests.r{end+1} = 'time';
            wp2requests.p{end+1} = '';
            blocksize_s = v.esetup.blockCreation.blockSize;
            obj = obj@Wp2DepKS( wp2requests, blocksize_s );
            obj.modelname = modelName;
            % TODO: model loading should include loading
            % a generic modelPredict function
            obj.model = v.model;
            v = load( [modelFileName '_scale.mat'] );
            obj.scale.translators = v.translators;
            obj.scale.factors = v.factors;
            [obj.scaleFunc, obj.tmpFuncs{1}, ~] = dynLoadMFun( [modelFileName '_scaleFunction.mat'] );
            [obj.featureFunc, obj.tmpFuncs{2}, obj.featureParam] = dynLoadMFun( [modelFileName '_featureFunction.mat'] );
            obj.invocationMaxFrequency_Hz = 4;
       end
        
        function delete( obj )
            delete( obj.tmpFuncs{1} );
            delete( obj.tmpFuncs{2} );
        end
        
        %% utility function for printing the obj
        function s = char( obj )
            s = [char@Wp2DepKS( obj ), '[', obj.modelname, ']'];
        end
        
        %% execute functionality
        function [b, wait] = canExecute( obj )
            signal = obj.getReqSignal( length( obj.wp2requests.r ) );
            lEnergy = std( ...
                signal{1}.getSignalBlock( obj.blocksize_s, obj.timeSinceTrigger )...
                );
            rEnergy = std( ...
                signal{2}.getSignalBlock( obj.blocksize_s, obj.timeSinceTrigger )...
                );
            
            b = (lEnergy + rEnergy >= 0.01);
            wait = false;
        end
        
        function execute( obj )
            wp2data = [];
            for z = 1:length( obj.wp2requests.r ) - 1
                wp2reqSignal = obj.getReqSignal( z );
                convWp2ReqSignal = [];
                convWp2ReqSignal.Data{1} = ...
                    wp2reqSignal{1}.getSignalBlock( obj.blocksize_s, obj.timeSinceTrigger );
                convWp2ReqSignal.Data{2} = ...
                    wp2reqSignal{2}.getSignalBlock( obj.blocksize_s, obj.timeSinceTrigger );
                convWp2ReqSignal.Name = wp2reqSignal{1}.Name;
                convWp2ReqSignal.Dimensions = wp2reqSignal{1}.Dimensions;
                convWp2ReqSignal.FsHz = wp2reqSignal{1}.FsHz;
                convWp2ReqSignal.Canal{1} = wp2reqSignal{1}.Canal;
                convWp2ReqSignal.Canal{2} = wp2reqSignal{2}.Canal;
                wp2data = [wp2data; convWp2ReqSignal];
            end
            
            features = obj.featureFunc( obj.featureParam, wp2data(:) );
            features = obj.scaleFunc( features, obj.scale.translators, obj.scale.factors );
            [~, ~, probs] = libsvmpredict( 0, features, obj.model, '-q -b 1' );
            %libsvmpredict is the renamed svmpredict of the LIBSVM package
            
            if obj.blackboard.verbosity > 0
                fprintf( 'Identity Hypothesis: %s with %i%% probability.\n', ...
                    obj.modelname, int16(probs(1)*100) );
            end
            identHyp = IdentityHypothesis( obj.modelname, probs(1), obj.blocksize_s );
            obj.blackboard.addData( 'identityHypotheses', identHyp, true, obj.trigger.tmIdx );
            notify( obj, 'KsFiredEvent', BlackboardEventData( obj.trigger.tmIdx ) );
        end
    end
end
