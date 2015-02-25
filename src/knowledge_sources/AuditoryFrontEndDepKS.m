classdef AuditoryFrontEndDepKS < AbstractKS
    % TODO: add description
    
    properties (SetAccess = private)
        requests;       % requests.r{1..k}: Auditory Front-End requests; requests.p{1..k}: according params
        blocksize_s;
    end

    methods
        function obj = AuditoryFrontEndDepKS( requests, blockSize_s )
            obj = obj@AbstractKS();
            obj.requests = requests;
            obj.blocksize_s = blockSize_s;
       end
        
        function delete( obj )
            %TODO: remove processors and handles in bb
        end
    end

    methods (Access = protected)

        function reqSignal = getAuditoryFrontEndRequest( obj, reqIdx )
            reqHash = AuditoryFrontEndKS.getRequestHash( obj.requests.r{reqIdx}, obj.requests.p{reqIdx} );
            reqSignal = obj.blackboard.signals(reqHash);
        end

        function bEnergy = hasSignalEnergy(obj, signal)
            bEnergy = false;
            length(signal)
            energy = 0;
            for ii=1:length(signal)
                energy = energy + std(signal{1}.getSignalBlock(obj.blocksize_s, ...
                                                               obj.timeSinceTrigger));
            end
            % FIXME: why we have chosen 0.01 as threshold?
            bEnergy = (energy >= 0.01);
        end

    end
end

% vim: set sw=4 ts=4 et tw=90:
