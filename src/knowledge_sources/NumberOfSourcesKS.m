classdef NumberOfSourcesKS < AbstractAMLTTPKS
    
    properties (SetAccess = private)
    end

    methods
        function obj = NumberOfSourcesKS( modelName, modelDir, ppRemoveDc )
            obj@AbstractAMLTTPKS( modelName, modelDir, ppRemoveDc );
            obj.setInvocationFrequency(4);
        end
        
        function execute( obj )
            afeData = obj.getAFEdata();
            afeData = obj.blockCreator.cutDataBlock( afeData, obj.timeSinceTrigger );
            
            locHypos = obj.blackboard.getLastData( 'sourcesAzimuthsDistributionHypotheses' );
            assert( numel( locHypos.data ) == 1 );
            afeData = DataProcs.DnnLocKsWrapper.addLocData( afeData, locHypos.data );
            
            obj.featureCreator.setAfeData( afeData );
            x = obj.featureCreator.constructVector();
            [d, score] = obj.model.applyModel( x{1} );
            d = round( d(1) );
            bbprintf(obj, '[NumberOfSourcesKS:] %s detecting %i% sources.\n', ...
                     obj.modelname, int16(d) );
            identHyp = NumberOfSourcesHypothesis( ...
                obj.modelname, score(1), d, obj.blockCreator.blockSize_s );
            obj.blackboard.addData( 'NumberOfSourcesHypotheses', identHyp, true, obj.trigger.tmIdx );
            notify( obj, 'KsFiredEvent', BlackboardEventData( obj.trigger.tmIdx ) );
        end
    end
end
