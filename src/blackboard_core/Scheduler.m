classdef Scheduler < handle
    
    properties (SetAccess = private)
        monitor;          % Blackboard monitor
        agendaIndex = 1;
    end
    
    methods
        function obj = Scheduler(monitor)
            obj.monitor = monitor;
        end
        function b = iterate(obj)
            b = false;
            num = length(obj.monitor.agenda);
            while obj.agendaIndex <= num
                ai = obj.monitor.agenda(obj.agendaIndex);
                ai.ks.execute;
                b = true;
                obj.agendaIndex = obj.agendaIndex + 1;
            end
            
        end
    end
end

