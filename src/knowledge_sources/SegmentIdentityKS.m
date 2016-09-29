classdef SegmentIdentityKS < AuditoryFrontEndDepKS
    
    properties (SetAccess = private)
        modelname;
        model;                 % classifier model
        featureCreator;
        blockCreator;
    end

    methods
        function obj = SegmentIdentityKS( modelName, modelDir, ppRemoveDc )
            modelFileName = [modelDir filesep modelName];
            v = load( [modelFileName '.model.mat'] );
            if ~isa( v.featureCreator, 'FeatureCreators.Base' )
                error( 'Loaded model''s featureCreator must implement FeatureCreators.Base.' );
            end
            afeRequests = v.featureCreator.getAFErequests();
%             if nargin > 3 && pp_bNormalizeRMS
%                 for ii = 1 : numel( afeRequests )
%                     afeRequests{ii}.params.replaceParameters( ...
%                                    genParStruct( 'pp_bNormalizeRMS', pp_bNormalizeRMS ) );
%                 end
%             end
            if nargin > 2 && ppRemoveDc
                for ii = 1 : numel( afeRequests )
                    afeRequests{ii}.params.replaceParameters( ...
                                   genParStruct( 'pp_bRemoveDC', ppRemoveDc ) );
                end
            end
            obj = obj@AuditoryFrontEndDepKS( afeRequests );
            obj.featureCreator = v.featureCreator;
            if isfield(v, 'blockCreator')
                if ~isa( v.blockCreator, 'BlockCreators.Base' )
                    error( 'Loaded model''s block creator must implement BeatureCreators.Base.' );
                end
            elseif isfield(v, 'blockSize_s')
                v.blockCreator = BlockCreators.StandardBlockCreator( v.blockSize_s, 0.5/3 );
            else
                % for models missing a block creator instance; let's hope
                % 0.5s was the block length used.
                v.blockCreator = BlockCreators.StandardBlockCreator( 0.5, 0.5/3 );
            end
            obj.blockCreator = v.blockCreator;
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
                bbprintf(obj, '[SegmentIdentitiyKS:] source %i at %i°: %s with %i%% score.\n', ...
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
