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

        function reqSignal = getReqSignal( obj, reqIdx )
            reqHash = AuditoryFrontEndKS.getRequestHash( obj.requests.r{reqIdx}, obj.requests.p{reqIdx} );
            reqSignal = obj.blackboard.signals(reqHash);
        end
    end
end
