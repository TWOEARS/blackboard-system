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
        function obj = IdentityKS( blackboard, modelName, modelVersion )
            modelFileName = [modelName '_' modelVersion];
            v = load( [modelFileName '_model.mat'] );
            wp2requests.r = v.esetup.wp2dataCreation.requests;
            wp2requests.p = v.esetup.wp2dataCreation.requestP;
            blocksize_s = v.esetup.blockCreation.blockSize;
            obj = obj@Wp2DepKS( blackboard, wp2requests, blocksize_s );
            obj.modelname = modelName;
            % TODO: model loading should include loading
            % a generic modelPredict function
            obj.model = v.model;
            v = load( [modelFileName '_scale.mat'] );
            obj.scale.translators = v.translators;
            obj.scale.factors = v.factors;
            [obj.scaleFunc, obj.tmpFuncs{1}, ~] = dynLoadMFun( [modelFileName '_scaleFunction.mat'] );
            [obj.featureFunc, obj.tmpFuncs{2}, obj.featureParam] = dynLoadMFun( [modelFileName '_featureFunction.mat'] );
       end
        
        function delete( obj )
            delete( obj.tmpFuncs{1} );
            delete( obj.tmpFuncs{2} );
        end
        
        function b = canExecute( obj )
            b = true;
        end
        
        function execute( obj )
            if obj.blackboard.verbosity > 0
                fprintf('-------- IdentityKS has fired.\n');
            end
            
            wp2data = [];
            for z = 1:length( obj.wp2requests.r )
                wp2reqSignal = obj.getReqSignal( z );
                convWp2ReqSignal = [];
                convWp2ReqSignal.Data{1} = wp2reqSignal{1}.getSignalBlock( obj.blocksize_s );
                convWp2ReqSignal.Data{2} = wp2reqSignal{2}.getSignalBlock( obj.blocksize_s );
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
            
            fprintf( 'Identity Hypothesis: %s with %i%% probability.\n', ...
                obj.modelname, int16(probs(1)*100) );
            identHyp = IdentityHypothesis( obj.modelname, probs(1), obj.blocksize_s );
            idx = obj.blackboard.addData( 'identityHypotheses', identHyp, true );
            notify( obj.blackboard, 'NewIdentityHypothesis', BlackboardEventData(idx) );
        end
    end
end
