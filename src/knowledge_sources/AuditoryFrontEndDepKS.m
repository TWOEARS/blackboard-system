classdef AuditoryFrontEndDepKS < AbstractKS
    % TODO: add description
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        requests;       % requests.r{1..k}: Auditory Front-End requests; requests.p{1..k}: according params
    end
    
    %% -----------------------------------------------------------------------------------
    methods

        function obj = AuditoryFrontEndDepKS( requests )
            obj = obj@AbstractKS();
            obj.requests = requests;
            %           example:
            %             requests{1}.name = 'modulation';
            %             requests{1}.params = genParStruct( ...
            %                 'nChannels', obj.amFreqChannels, ...
            %                 'am_type', 'filter', ...
            %                 'am_nFilters', obj.amChannels ...
            %                 );
            %             requests{2}.name = 'ratemap_magnitude';
            %             requests{2}.params = genParStruct( ...
            %                 'nChannels', obj.freqChannels ...
            %                 );
        end
        %% -------------------------------------------------------------------------------
        
        function delete( obj )
            %TODO: remove processors and handles in bb
        end
        %% -------------------------------------------------------------------------------
        
    end
    
    %% -----------------------------------------------------------------------------------
    methods (Access = protected)
        
        function afeSignals = getAFEdata( obj )
            afeSignals = containers.Map( 'KeyType', 'char', 'ValueType', 'any' );
            for ii = 1 : length( obj.requests )
                reqHash = AuditoryFrontEndKS.getRequestHash( obj.requests{ii} );
                afeSignals(obj.requests{ii}.name) = obj.blackboard.signals(reqHash);
            end
        end
        %% -------------------------------------------------------------------------------
    end
    
end
