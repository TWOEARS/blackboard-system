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
                ilds, ic, ratemap, ratemapF1)
            obj.blockNo = blockNo;
            obj.headOrientation = headOrientation;
            obj.itds = itds;
            obj.ilds = ilds;
            obj.ic = ic;
            obj.ratemap = ratemap;
            obj.ratemapF1 = ratemapF1;
        end
        function setSeenByLocationKS(obj)
            obj.seenByLocationKS = true;
        end
    end
    
end
