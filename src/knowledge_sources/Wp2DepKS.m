classdef Wp2DepKS < AbstractKS
    
    properties (SetAccess = private)
        wp2requests;    % wp2requests.r{1..k}: wp2 requests; wp2requests.p{1..k}: according params
        blocksize_s;
    end

    methods
        function obj = Wp2DepKS( wp2requests, blockSize_s )
            obj = obj@AbstractKS();
            obj.wp2requests = wp2requests;
            obj.blocksize_s = blockSize_s;
       end
        
        function delete( obj )
            %TODO: remove processors and handles in bb
        end
    end
    
    methods (Access = protected)

        function reqSignal = getReqSignal( obj, reqIdx )
            wp2reqHash = Wp2KS.getRequestHash( obj.wp2requests.r{reqIdx}, obj.wp2requests.p{reqIdx} );
            reqSignal = obj.blackboard.wp2signals(wp2reqHash);
        end
    end
end
