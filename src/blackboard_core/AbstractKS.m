
classdef AbstractKS < handle
    properties (SetAccess = private)
        blackboard;
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
    end
end
