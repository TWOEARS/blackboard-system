classdef SignalBlock < handle
    % SignalBlock represents a block of binaural signals on the lowest
    % level of the blackboard system.
    
    properties (SetAccess = private)
        blockNo;                           % Block number
        signals;                           % l/r ear signal
        headOrientation = 0;               % head orientation angle for this block
        seenByPeripheryKS = false;         % flag indicating if the block was already processed
    end
    
    methods
        function obj = SignalBlock(blockNo, headOrientation, signals)
            obj.blockNo = blockNo;
            %obj.blockStart = blockStart;
            %obj.blockEnd = blockEnd;
            obj.headOrientation = headOrientation;
            obj.signals = signals;
        end
        function obj = setSeenByPeripheryKS(obj)
            obj.seenByPeripheryKS = true;
        end
    end
    
end
