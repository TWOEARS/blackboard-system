classdef IdentityKS < AuditoryFrontEndDepKS
    
    properties (SetAccess = private)
        modelname;
        model;                 % classifier model
        featureCreator;
        blockCreator;
    end

    methods
        function obj = IdentityKS( modelName, modelDir, ppRemoveDc )
            modelFileName = [modelDir filesep modelName];
            v = load( db.getFile( [modelFileName '.model.mat'] ) );
            if ~isa( v.featureCreator, 'FeatureCreators.Base' )
                error( 'Loaded model''s featureCreator must implement FeatureCreators.Base.' );
            end
            afeRequests = v.featureCreator.getAFErequests();
%             if nargin > 2 && pp_bNormalizeRMS
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
                % for models missing a block creator instance
                v.blockCreator = BlockCreators.StandardBlockCreator( 0.5, 0.5/3 );
            end
            obj.blockCreator = v.blockCreator;
            obj.model = v.model;
            obj.modelname = modelName;
            obj.invocationMaxFrequency_Hz = 4;
        end
        
        function setInvocationFrequency( obj, newInvocationFrequency_Hz )
            % Youssef @Ivo: wieso nicht im Abstract Class?
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
