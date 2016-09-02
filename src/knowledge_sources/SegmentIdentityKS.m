classdef SegmentIdentityKS < AuditoryFrontEndDepKS
    
    properties (SetAccess = private)
        modelname;
        model;                 % classifier model
        featureCreator;
    end

    methods
        function obj = SegmentIdentityKS( modelName, modelDir )
            modelFileName = [modelDir filesep modelName];
            v = load( [modelFileName '.model.mat'] );
            if ~isa( v.featureCreator, 'featureCreators.Base' )
                error( 'Loaded model''s featureCreator must implement featureCreators.Base.' );
            end
            obj = obj@AuditoryFrontEndDepKS( v.featureCreator.getAFErequests() );
            obj.featureCreator = v.featureCreator;
            obj.model = v.model;
            obj.modelname = modelName;
            obj.invocationMaxFrequency_Hz = 4;
        end
        
        function setInvocationFrequency( obj, newInvocationFrequency_Hz )
            obj.invocationMaxFrequency_Hz = newInvocationFrequency_Hz;
        end
        
        %% utility function for printing the obj
        function s = char( obj )
            s = [char@AuditoryFrontEndDepKS( obj ), '[', obj.modelname, ']'];
        end
        
        %% execute functionality
        function [b, wait] = canExecute( obj )
            b = true;
            wait = false;
        end
        
        function execute( obj )
            afeData = obj.getAFEdata();
            afeData = obj.featureCreator.cutDataBlock( afeData, ...
                obj.timeSinceTrigger );
            
            mask = obj.blackboard.getLastData('segmentationHypotheses', ...
                obj.trigger.tmIdx);
            % create masked copy of afeData
            for idx_mask = 1 : numel(mask.data)
                afeData_masked = obj.maskAFEData( afeData, ...
                    mask.data(idx_mask).softMask, ...
                    mask.data(idx_mask).cfHz, ...
                    mask.data(idx_mask).hopSize );
                
                obj.featureCreator.setAfeData( afeData_masked );
                x = obj.featureCreator.constructVector();
                [~, score] = obj.model.applyModel( x{1} );
                bbprintf(obj, '[SegmentIdentitiyKS:] source %i: %s with %i%% probability.\n', ...
                     idx_mask, obj.modelname, int16(score(1)*100) );
                identHyp = IdentityHypothesis( ...
                    obj.modelname, score(1), ...
                    obj.featureCreator.labelBlockSize_s );
                obj.blackboard.addData( 'identityHypotheses', ...
                    identHyp, true, obj.trigger.tmIdx );
            end

            notify( obj, 'KsFiredEvent', ...
                BlackboardEventData( obj.trigger.tmIdx ) );
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
