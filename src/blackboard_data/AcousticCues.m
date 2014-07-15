classdef AcousticCues < handle
    % SPATAILCUES
    
    properties (SetAccess = private)
        blockNo;         % Block number
        itds;            % ITD cues
        ilds;            % ILD cues
        ic;              % IC
        ratemap;         % Magnitude ratemap
        headOrientation; % head orientation used to generate the cues
        seenByLocationKS = false;
    end
    
    methods
        function obj = AcousticCues(blockNo, headOrientation, itds, ...
                ilds, ic, ratemap)
            obj.blockNo = blockNo;
            obj.headOrientation = headOrientation;
            obj.itds = itds;
            obj.ilds = ilds;
            obj.ic = ic;
            obj.ratemap = ratemap;
        end
        function setSeenByLocationKS(obj)
            obj.seenByLocationKS = true;
        end
    end
    
end
