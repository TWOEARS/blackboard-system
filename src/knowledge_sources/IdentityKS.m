classdef IdentityKS < AuditoryFrontEndDepKS
    
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
            requests.r = v.setup.dataCreation.requests;
            requests.p = v.setup.dataCreation.requestP;
            requests.r{end+1} = 'time';
            requests.p{end+1} = '';
            blocksize_s = v.setup.blockCreation.blockSize;
            obj = obj@AuditoryFrontEndDepKS( requests, blocksize_s );
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
            s = [char@AuditoryFrontEndDepKS( obj ), '[', obj.modelname, ']'];
        end
        
        %% execute functionality
        function [b, wait] = canExecute( obj )
%            signal = obj.getReqSignal( length( obj.requests.r ) );
%             lEnergy = std( ...
%                 signal{1}.getSignalBlock( obj.blocksize_s, obj.timeSinceTrigger )...
%                 );
%             rEnergy = std( ...
%                 signal{2}.getSignalBlock( obj.blocksize_s, obj.timeSinceTrigger )...
%                 );
%             
%             b = (lEnergy + rEnergy >= 0.01);
            b = true;
            wait = false;
        end
        
        function execute( obj )
            data = [];
            for z = 1:length( obj.requests.r ) - 1
                reqSignal = obj.getReqSignal( z );
                convReqSignal = [];
                convReqSignal.Data{1} = ...
                    reqSignal{1}.getSignalBlock( obj.blocksize_s, obj.timeSinceTrigger );
                convReqSignal.Data{2} = ...
                    reqSignal{2}.getSignalBlock( obj.blocksize_s, obj.timeSinceTrigger );
                convReqSignal.Name = reqSignal{1}.Name;
                convReqSignal.Dimensions = reqSignal{1}.Dimensions;
                convReqSignal.FsHz = reqSignal{1}.FsHz;
                convReqSignal.Canal{1} = reqSignal{1}.Canal;
                convReqSignal.Canal{2} = reqSignal{2}.Canal;
                data = [data; convReqSignal];
            end
            
            features = obj.featureFunc( obj.featureParam, data(:) );
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
