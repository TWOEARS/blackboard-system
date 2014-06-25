classdef PeripherySignal < handle
    % GAMMATONEOUTPUT represents a block of binaural signals
    
    properties (SetAccess = private)
        blockNo;                   % Block No
        signals;                   % WP2-style peripher signal struct
        headOrientation = 0;       % head orientation angle for this block
    end
    
    methods
        function obj = PeripherySignal(blockNo, headOrientation, peripherySignal)
            obj.blockNo = blockNo;
            obj.headOrientation = headOrientation;
            obj.signals = peripherySignal;
        end
    end
    
end
