classdef Scheduler < handle
    
    properties (SetAccess = private)
        monitor;          % Blackboard monitor
    end
    
    methods
        function obj = Scheduler(monitor)
            obj.monitor = monitor;
        end
        
        %% main scheduler loop
        %   processes all agenda items that are executable
        %   executes in order of attentional priority
        function processAgenda(obj)
            while ~isempty( obj.monitor.agenda )
                agendaOrder = obj.generateAgendaOrder();
                exctdKsi = obj.executeFirstExecutableAgendaOrderItem( agendaOrder );
                if ~exctdKsi
                    obj.monitor.agenda(:) = []; % rm the non-executable KSIs
                    % TODO: maybe the KSs should decide themselves whether
                    % to be removed from the agenda or not in case of
                    % canExecute returning false?
                    break; 
                end;
            end
        end

        %% inner scheduler loop
        %   processes the first item on the prioritized agenda list that's 
        %   executable
        %   
        %   exctdKsi:   true if a KSi has been executed <=> false if no KSi
        %               was executable
        function exctdKsi = executeFirstExecutableAgendaOrderItem( obj, agendaOrder )
            exctdKsi = false;
            for ai = agendaOrder
                nextKsi = obj.monitor.agenda(ai);
                nextKsi.ks.setActiveArgument( nextKsi.triggerSndTimeIdx );
                if nextKsi.ks.canExecute()
                    nextKsi.ks.execute;
                    obj.monitor.pastAgenda(end+1) = nextKsi;
                    obj.monitor.agenda(ai) = [];
                    exctdKsi = true;
                    break;
                end
            end
        end

        %% generate a prioritized list of agenda items
        % at the moment, the list is only considering the attentional
        % priorities
        function agendaOrder = generateAgendaOrder( obj )
            attendPrios = obj.getAgendaAttentionalPriorities();
            agendaOrder = attendPrios(2,:);
        end
        
        %% function attendPrios = getAgendaAttentionalPriorities( obj )
        %   get a list of agenda items sorted by their attentional
        %   priorities, from high to low
        %   
        %   attendPrios(1,:):   the priority values
        %   attendPrios(2,:):   the respective index of the item in the
        %                       agenda
        function attendPrios = getAgendaAttentionalPriorities( obj )
            attendPrios = arrayfun( @(x)(x.ks.attentionalPriority), obj.monitor.agenda );
            [attendPrios, apIx] = sort( attendPrios, 'descend' );
            attendPrios = [attendPrios; apIx];
        end
        
        %% function triggerTimes = getAgendaTriggerTimes( obj )
        %   get a list of agenda items sorted by the time they have been
        %   added to the agenda, from earlier to later
        %   
        %   triggerTimes(1,:):  the triggering times
        %   triggerTimes(2,:):	the respective index of the item in the
        %                       agenda
        function triggerTimes = getAgendaTriggerTimes( obj )
            triggerTimes = arrayfun( @(x)(x.triggerSndTimeIdx), obj.monitor.agenda );
            [triggerTimes, ttIx] = sort( triggerTimes, 'ascend' );
            triggerTimes = [triggerTimes; ttIx];
        end
        
    end
end

