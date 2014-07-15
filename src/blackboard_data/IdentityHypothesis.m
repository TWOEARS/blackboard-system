classdef IdentityHypothesis < Hypothesis
    
    properties (SetAccess = private)
        blockNo;                           % Block number
        label;
        decVal;
    end
    
    methods
        function obj = IdentityHypothesis( blockNo, label, decVal )
            obj.blockNo = blockNo;
            obj.label = label;
            obj.decVal = decVal;
        end
        
        function idText = getIdentityText( obj )
            idText = obj.label;
        end
    end
    
end
