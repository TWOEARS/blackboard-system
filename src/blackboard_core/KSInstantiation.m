classdef KSInstantiation < handle
    
    properties (SetAccess = private)
        ks;            % Triggered knowledge source
        triggerSndTimeIdx;
        triggerSrc;
    end
    
    methods
        function obj = KSInstantiation( ks, triggerSoundTimeIdx, triggerSource )
            obj.ks = ks;
            obj.triggerSndTimeIdx = triggerSoundTimeIdx;
            obj.triggerSrc = triggerSource;
        end
    end
    
end
