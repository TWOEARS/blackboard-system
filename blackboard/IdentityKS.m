classdef IdentityKS < AbstractKS
    
    properties (SetAccess = private)
        modelname;
        model;                 % classifier model
        featureFunc;
        featureParam;
        scaleFunc;
        scale;
        tmpFuncs;
        activeIndex = 0;       % The index of AcousticCues to be processed
    end
    
    methods
        function obj = IdentityKS( blackboard, modelName, modelVersion )
            obj = obj@AbstractKS( blackboard );
            obj.modelname = modelName;
            modelFileName = ['identificationModels/' modelName '_' modelVersion];
            v = load( [modelFileName '_model.mat'] );
            obj.model = v.model;
            v = load( [modelFileName '_scale.mat'] );
            obj.scale.translators = v.translators;
            obj.scale.factors = v.factors;
            [obj.scaleFunc, obj.tmpFuncs{1}, ~] = dynLoadMFun( [modelFileName '_scaleFunction.mat'] );
            [obj.featureFunc, obj.tmpFuncs{2}, obj.featureParam] = dynLoadMFun( [modelFileName '_featureFunction.mat'] );
            %dynLoadMFun can be found at software/tools
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
            b = obj.activeIndex == 1;
        end
        
        function execute( obj )
            acousticCues = obj.blackboard.acousticCues{obj.activeIndex};
            
            fprintf( '-------- IdentityKS (%s) has fired\n', obj.modelname );
            
            rmWp2.data = acousticCues.ratemap;
            rmWp2.name = 'ratemap_magnitude';
            features = obj.featureFunc( obj.featureParam, rmWp2 );
            features = obj.scaleFunc( features', obj.scale.translators, obj.scale.factors );
            [label, ~, decVal] = libsvmpredict( [0], features, obj.model, '-q' );
            %libsvmpredict is the renamed svmpredict of the LIBSVM package
            
            if label == +1
                identHyp = IdentityHypothesis( acousticCues.blockNo, obj.modelname, decVal );
                idx = obj.blackboard.addIdentityHypothesis( identHyp );
                notify( obj.blackboard, 'NewIdentityHypothesis', BlackboardEventData(idx) );
            end
            
            obj.activeIndex = 0; %TODO: does this have any effect??
        end
    end
end
