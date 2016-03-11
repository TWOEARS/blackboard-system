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
        function afeBlock = maskAFEData( afeData, mask, maskHopSize )
            afeBlock = containers.Map( 'KeyType', 'int32', 'ValueType', 'any' );
            for afeKey = afeData.keys
                afeSignal = afeData(afeKey{1});
                % skip masking of spectral features
                if ~strcmpi( afeSignal{1}.Name, 'spectralFeatures' )
                    if isa( afeSignal, 'cell' )
                        afeSignalExtract{1} = afeSignal{1}.maskSignalCopy( mask, maskHopSize );
                        afeSignalExtract{2} = afeSignal{2}.maskSignalCopy( mask, maskHopSize );
                    else
                        afeSignalExtract = afeSignal.maskSignalCopy( mask, maskHopSize );
                    end
                else
                    afeSignalExtract = afeSignal;
                end
                afeBlock(afeKey{1}) = afeSignalExtract;
            end
        end
    end % static methods
end
