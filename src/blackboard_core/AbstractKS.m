classdef AbstractKS < handle

    properties (SetAccess = protected)
        blackboard;
        attentionalPriority = 0;
        allowDoubleInvocation = 1;  % if 0, a KS will only be triggered 
                                    % if not already in the agenda.
    end
    
    events
        KsFiredEvent
    end
    
    methods (Abstract)
        % find out if the precondition for the expert is met
        % returns a boolean
        b = canExecute(obj) 
        % the function through which an expert performs its action
        % no result is returned, but the contents of the blackboard
        % may be modified
        execute(obj)
    end
    
    methods

        function obj = AbstractKS(blackboard)
            if nargin > 0
                obj.blackboard = blackboard;
            end
        end
        
        function setActiveArgument(obj, arg)
        end
        
        function focus( obj )
            obj.attentionalPriority = obj.attentionalPriority + 1;
        end
        
        function unfocus( obj )
            obj.attentionalPriority = obj.attentionalPriority - 1;
        end
        
        function resetFocus( obj )
            obj.attentionalPriority = 0;
        end
    end
    
end
