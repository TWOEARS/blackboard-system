classdef IdentityHypothesis < Hypothesis
    
    properties (SetAccess = private)
        label;
        p;
    end
    
    methods
        function obj = IdentityHypothesis( label, p )
            obj = obj@Hypothesis();
            obj.label = label;
            obj.p = p;
        end
        
        function idText = getIdentityText( obj )
            idText = obj.label;
        end
    end
    
end
