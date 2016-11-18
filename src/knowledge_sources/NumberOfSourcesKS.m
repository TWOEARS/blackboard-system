classdef NumberOfSourcesKS < AbstractAMLTTPKS
    
    properties (SetAccess = private)
    end

    methods
        function obj = NumberOfSourcesKS( modelName, modelDir, ppRemoveDc )
            obj@AbstractAMLTTPKS( modelName, modelDir, ppRemoveDc );
            obj.setInvocationFrequency(inf);
        end
        
        function visualise(obj)
            if ~isempty(obj.blackboardSystem.locVis)
                nSrcsHyp = obj.blackboard.getData( ...
                    'NumberOfSourcesHypotheses', obj.trigger.tmIdx).data;
                obj.blackboardSystem.locVis.setNumberOfSourcesText(nSrcsHyp.n);
            end
        end
    end
    
    methods (Access = protected)        
        function amlttpExecute( obj, afeBlock )
%             locHypos = obj.blackboard.getLastData( 'sourcesAzimuthsDistributionHypotheses' );
            locHypos = obj.blackboard.getLastData( 'locationHypothesis' );
            assert( numel( locHypos.data ) == 1 );
            afeBlock = DataProcs.DnnLocKsWrapper.addLocData( afeBlock, locHypos.data );
            
            obj.featureCreator.setAfeData( afeBlock );
            
            x = obj.featureCreator.constructVector();
            [d, score] = obj.model.applyModel( x{1} );
            d = round( d(1) );
            bbprintf(obj, '[NumberOfSourcesKS:] %s detecting %i sources.\n', ...
                     obj.modelname, int16(d) );
            identHyp = NumberOfSourcesHypothesis( ...
                obj.modelname, score(1), d, obj.blockCreator.blockSize_s );
            obj.blackboard.addData( 'NumberOfSourcesHypotheses', identHyp, true, obj.trigger.tmIdx );
        end
    end
end
