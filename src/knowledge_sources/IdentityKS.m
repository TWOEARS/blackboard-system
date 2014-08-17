classdef IdentityKS < AbstractKS
    
    properties (SetAccess = private)
        modelname;
        model;                 % classifier model
        wp2requests;           % model training setup, including wp2 setup
        featureFunc;
        featureParam;
        blocksize_s;
        scaleFunc;
        scale;
        tmpFuncs;
    end

    methods (Static)
        function createProcessors( wp2ks, idks )
            for z = 1:length( idks.wp2requests )
                wp2ks.addProcessor( idks.wp2requests.r{z}, idks.wp2requests.p{z} );
            end
        end
    end
    
    methods
        function obj = IdentityKS( blackboard, modelName, modelVersion )
            obj = obj@AbstractKS( blackboard );
            obj.modelname = modelName;
            modelFileName = [modelName '_' modelVersion];
            v = load( [modelFileName '_model.mat'] );
            % TODO: model loading should include loading
            % a generic modelPredict function
            obj.model = v.model;
            obj.wp2requests.r = v.esetup.wp2dataCreation.requests;
            obj.wp2requests.p = v.esetup.wp2dataCreation.requestP;
            obj.blocksize_s = v.esetup.blockCreation.blockSize;
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
                wp2reqHash = Wp1Wp2KS.getRequestHash( obj.wp2requests.r{z}, obj.wp2requests.p{z} );
                wp2reqSignal = obj.blackboard.wp2signals(wp2reqHash);
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
            [label, ~, probs] = libsvmpredict( [0], features, obj.model, '-q -b 1' );
            %libsvmpredict is the renamed svmpredict of the LIBSVM package
            
            if label == +1
                fprintf( 'Positive Identity Hypothesis: %s with %i%% probability.\n', ...
                    obj.modelname, int16(probs(1)*100) );
            end
            identHyp = IdentityHypothesis( 0, obj.modelname, probs(1) );
            idx = obj.blackboard.addIdentityHypothesis( identHyp );
            notify( obj.blackboard, 'NewIdentityHypothesis', BlackboardEventData(idx) );
        end
    end
end
