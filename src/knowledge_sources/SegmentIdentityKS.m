classdef SegmentIdentityKS < AbstractAMLTTPKS
    
    properties (SetAccess = private)
        modelname;
        model;                 % classifier model
        featureCreator;
        blockCreator;
    end

    methods
        function obj = SegmentIdentityKS( modelName, modelDir, ppRemoveDc )
            obj@AbstractAMLTTPKS( modelName, modelDir, ppRemoveDc );
            obj.setInvocationFrequency(4);
        end
    end
    
    methods (Access = protected)
        function prepAFEData( obj )
        end
        
        function amlttpExecute( obj )
            afeData = obj.getAFEdata();
            afeData = obj.blockCreator.cutDataBlock( afeData, obj.timeSinceTrigger );
            
            mask = obj.blackboard.getLastData('segmentationHypotheses', ...
                obj.trigger.tmIdx);
            % create masked copy of afeData
            d = [];
            score = {};
            estSrcAzm = [];
            for ii = 1 : numel(mask.data)
                afeData_masked = SegmentIdentityKS.maskAFEData( afeData, ...
                    mask.data(ii).softMask, ...
                    mask.data(ii).cfHz, ...
                    mask.data(ii).hopSize );
                
                obj.featureCreator.setAfeData( afeData_masked );
                x = obj.featureCreator.constructVector();
                [d(ii), score{ii}] = obj.model.applyModel( x{1} );
                estSrcAzm(ii) = mask.data(ii).refAzm;
                bbprintf(obj, '[SegmentIdentitiyKS:] source %i at %i�: %s with %i%% score.\n', ...
                     ii, estSrcAzm(ii), obj.modelname, int16(score{ii}(1)*100) );
            end
            [score, maxScoreIdx] = max( cellfun( @(c)(c(1)), score ) );
            d = d(maxScoreIdx);
            identHyp = IdentityHypothesis( ...
                obj.modelname, score, d, obj.blockCreator.blockSize_s );
            obj.blackboard.addData( 'identityHypotheses', ...
                identHyp, true, obj.trigger.tmIdx );
            % TODO: use joint LocIdHypo or add azm to IdHypo (then also
            % plot azm)
        end
    end
    
    methods (Static)
        function afeBlock = maskAFEData( afeData, mask, cfHz, maskHopSize )
            afeBlock = containers.Map( 'KeyType', 'int32', 'ValueType', 'any' );
            for afeKey = afeData.keys
                afeSignal = afeData(afeKey{1});
                if isa( afeSignal, 'cell' )
                    for ii = 1 : numel( afeSignal )
                        if isa( afeSignal{ii}, 'TimeFrequencySignal' ) || ...
                                isa( afeSignal{ii}, 'CorrelationSignal' ) || ...
                                isa( afeSignal{ii}, 'ModulationSignal' )
                            afeSignalExtract{ii} = ...
                                   afeSignal{ii}.maskSignalCopy( mask, cfHz, maskHopSize );
                        else
                            afeSignalExtract{ii} = afeSignal{ii};
                        end
                    end
                else
                    if isa( afeSignal, 'TimeFrequencySignal' ) || ...
                            isa( afeSignal, 'CorrelationSignal' ) || ...
                            isa( afeSignal, 'ModulationSignal' )
                        afeSignalExtract = ...
                                      afeSignal.maskSignalCopy( mask, cfHz, maskHopSize );
                    else
                        afeSignalExtract = afeSignal;
                    end
                end
                afeBlock(afeKey{1}) = afeSignalExtract;
                clear afeSignalExtract;
            end
        end
    end % static methods
end
