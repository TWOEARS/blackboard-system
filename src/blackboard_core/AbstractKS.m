classdef AbstractKS < handle

    properties (SetAccess = protected)
        blackboard;
        attentionalPriority = 0;
        allowDoubleInvocation = 0;  % if 0, a KS will only be triggered 
                                    % if not already in the agenda.
        invocationMaxFrequency_Hz = 2;
        lastExecutionTime_s = -inf;
        trigger;                    % struct consisting of elements
                                    % src,tmIdx,eventName
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
        
        function setActiveArgument(obj, triggerSrc, triggerTmIdx, eventName)
            obj.trigger.src = triggerSrc;
            obj.trigger.tmIdx = triggerTmIdx;
            obj.trigger.eventName = eventName;
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
        
        function timeStamp( obj )
            obj.lastExecutionTime_s = obj.blackboard.currentSoundTimeIdx;
        end
        
        function executeYet = isMaxInvocationFreqMet( obj )
            timeSinceLastExec = ...
                obj.blackboard.currentSoundTimeIdx - obj.lastExecutionTime_s;
            executeYet = timeSinceLastExec >= (1.0 / obj.invocationMaxFrequency_Hz);
        end
        
        function tmOffset = timeSinceTrigger( obj )
            tmOffset = (obj.blackboard.currentSoundTimeIdx - obj.trigger.tmIdx);
        end
    end
    
end
