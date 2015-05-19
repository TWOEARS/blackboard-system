classdef AuditoryFrontEndDepKS < AbstractKS
    % TODO: add description
<<<<<<< HEAD
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = private)
        requests;       % requests.r{1..k}: Auditory Front-End requests; requests.p{1..k}: according params
=======

    properties (SetAccess = private)
        requests;       % requests.r{1..k}: Auditory Front-End requests;
                        % requests.p{1..k}: according params
        blocksize_s;
>>>>>>> quality1
    end
    
    %% -----------------------------------------------------------------------------------
    methods
<<<<<<< HEAD

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
=======
        function obj = AuditoryFrontEndDepKS(requests, blockSize_s)
            obj = obj@AbstractKS();
            obj.requests = requests;
            obj.blocksize_s = blockSize_s;
       end

        function delete(obj)
>>>>>>> quality1
            %TODO: remove processors and handles in bb
        end
        %% -------------------------------------------------------------------------------
        
    end
<<<<<<< HEAD
    
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
=======

    methods (Access = protected)

        function reqSignal = getAuditoryFrontEndRequest(obj, reqIdx)
            reqHash = AuditoryFrontEndKS.getRequestHash(obj.requests.r{reqIdx}, ...
                                                        obj.requests.p{reqIdx});
            reqSignal = obj.blackboard.signals(reqHash);
        end

        function bEnergy = hasSignalEnergy(obj, signal)
            bEnergy = false;
            energy = 0;
            for ii=1:length(signal)
                energy = energy + std(signal{1}.getSignalBlock(obj.blocksize_s, ...
                                                               obj.timeSinceTrigger));
            end
            % FIXME: why we have chosen 0.01 as threshold?
            bEnergy = (energy >= 0.01);
        end

>>>>>>> quality1
    end
    
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
