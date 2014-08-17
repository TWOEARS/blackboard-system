classdef IdentityKS < AbstractKS
    
    properties (SetAccess = private)
        modelname;
        model;                 % classifier model
        wp2requests;                % model training setup, including wp2 setup
        featureFunc;
        featureParam;
        scaleFunc;
        scale;
        tmpFuncs;
        activeIndex = 0;       % The index of AcousticCues to be processed
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
        
        function setActiveArgument( obj, arg )
            obj.activeIndex = arg;
        end
        
        function b = canExecute( obj )
            %TODO: senseless?? 
            b = true;
        end
        
        function execute( obj )
            wp2data = [];
            for z = 1:length( obj.wp2requests.r )
                wp2reqHash = Wp2KS.getRequestHash( obj.wp2requests.r{z}, obj.wp2requests.p{z} );
                wp2reqSignal = obj.blackboard.wp2signals(wp2reqHash);
                convWp2ReqSignal = [];
                convWp2ReqSignal.Data{1} = wp2reqSignal{1}.Data;
                convWp2ReqSignal.Data{2} = wp2reqSignal{2}.Data;
                convWp2ReqSignal.Name = wp2reqSignal{1}.Name;
                convWp2ReqSignal.Dimensions = wp2reqSignal{1}.Dimensions;
                convWp2ReqSignal.FsHz = wp2reqSignal{1}.FsHz;
                convWp2ReqSignal.Canal{1} = wp2reqSignal{1}.Canal;
                convWp2ReqSignal.Canal{2} = wp2reqSignal{2}.Canal;
                wp2data = [wp2data; convWp2ReqSignal];
            end
            
            features = obj.featureFunc( obj.featureParam, wp2data(:) );
            features = obj.scaleFunc( features, obj.scale.translators, obj.scale.factors );
            [label, ~, decVal] = libsvmpredict( [0], features, obj.model, '-q -b 1' );
            %libsvmpredict is the renamed svmpredict of the LIBSVM package
            
            identHyp = IdentityHypothesis( 0, obj.modelname, decVal(1) );
            idx = obj.blackboard.addIdentityHypothesis( identHyp );
            notify( obj.blackboard, 'NewIdentityHypothesis', BlackboardEventData(idx) );
            
            obj.activeIndex = 0; %TODO: does this have any effect??
        end
    end
end
