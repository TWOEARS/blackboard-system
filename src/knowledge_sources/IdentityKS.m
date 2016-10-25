classdef IdentityKS < AbstractAMLTTPKS
    % IdentityKS drives sound identification 
    % deployment system
    properties (SetAccess = private)
    end

    methods
        function obj = IdentityKS( modelName, modelDir, ppRemoveDc )
            obj@AbstractAMLTTPKS( modelName, modelDir, ppRemoveDc );
            obj.setInvocationFrequency(4);
        end
        
        function execute( obj )
            afeData = obj.getAFEdata();
            afeData = obj.blockCreator.cutDataBlock( afeData, obj.timeSinceTrigger );
            
            obj.featureCreator.setAfeData( afeData );
            x = obj.featureCreator.constructVector();
            [d, score] = obj.model.applyModel( x{1} );
            
            bbprintf(obj, '[IdentitiyKS:] %s with %i%% probability.\n', ...
                     obj.modelname, int16(score(1)*100) );
            identHyp = IdentityHypothesis( ...
                obj.modelname, score(1), d(1), obj.blockCreator.blockSize_s );
            obj.blackboard.addData( 'identityHypotheses', identHyp, true, obj.trigger.tmIdx );
            notify( obj, 'KsFiredEvent', BlackboardEventData( obj.trigger.tmIdx ) );
        end
    end
end
