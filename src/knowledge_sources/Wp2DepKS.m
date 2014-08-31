classdef Wp2DepKS < AbstractKS
    
    properties (SetAccess = private)
        wp2requests;    % wp2requests.r{1..k}: wp2 requests; wp2requests.p{1..k}: according params
        blocksize_s;
    end

    methods (Static)
        function createProcessors( wp2ks, wp2depKs )
            for z = 1:length( wp2depKs.wp2requests.r )
                wp2ks.addProcessor( wp2depKs.wp2requests.r{z}, wp2depKs.wp2requests.p{z} );
            end
        end
    end
    
    methods
        function obj = Wp2DepKS( blackboard, wp2requests, blockSize_s )
            obj = obj@AbstractKS( blackboard );
            obj.wp2requests = wp2requests;
            obj.blocksize_s = blockSize_s;
       end
        
        function delete( obj )
            %TODO: remove processors and handles in bb
        end
    end
    
    methods (Access = protected)

        function wp2signals = getWp2Signals( obj )
            wp2signals = [];
            for z = 1:length( obj.wp2requests.r )
                wp2reqHash = Wp1Wp2KS.getRequestHash( obj.wp2requests.r{z}, obj.wp2requests.p{z} );
                wp2reqSignal = obj.blackboard.wp2signals(wp2reqHash);
                convWp2ReqSignal = [];
                convWp2ReqSignal.Data{1} = wp2reqSignal{1}.getSignalBlock( obj.blocksize_s );
                convWp2ReqSignal.Data{2} = wp2reqSignal{2}.getSignalBlock( obj.blocksize_s );
                convWp2ReqSignal.Name = wp2reqSignal{1}.Name;
                convWp2ReqSignal.Dimensions = wp2reqSignal{1}.Dimensions;
                convWp2ReqSignal.FsHz = wp2reqSignal{1}.FsHz;
                convWp2ReqSignal.Canal{1} = wp2reqSignal{1}.Canal;
                convWp2ReqSignal.Canal{2} = wp2reqSignal{2}.Canal;
                wp2signals = [wp2signals; convWp2ReqSignal];
            end
        end
    end
end
