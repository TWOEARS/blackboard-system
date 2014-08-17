classdef BlackboardMonitor < handle
    %AgendaManager   
    %   Detailed explanation goes here

    properties (SetAccess = private)
        agenda;                % Agenda contains KSIs
        eventRegister;         % A register mapping an event to one or more KSs
        blackboard;
    end
    
    methods(Static)
        function n = rankKS(ks)
            mc = metaclass(ks);
            switch mc.Name;
                case 'Wp1Wp2KS'
                    n = 10;
                case 'LocationKS'
                	n = 20;
                case 'IdentityKS'
                	n = 15;
                case 'ConfusionKS'
                	n = 30;
                case 'RotationKS'
                	n = 40;
                case 'ConfusionSolvingKS'
                	n = 50;
                otherwise
                    n = 20;
            end
        end
    end
    
    methods
        function obj = BlackboardMonitor(bb)
            obj.eventRegister = containers.Map;
            obj.blackboard = bb;
        end
        
        function registerEvent(obj, eventName, varargin)
            if ~obj.eventRegister.isKey(eventName)
                addlistener(obj.blackboard, eventName, @obj.handleEvent);
                obj.eventRegister(eventName) = varargin;
            else
                obj.eventRegister(eventName) = [obj.eventRegister(eventName) varargin];
            end
        end
        
        function addKSI(obj, ks)
            ksi = KSInstantiation(ks);
            obj.agenda = [obj.agenda ksi];
        end
        
        function handleEvent(obj, src, evnt)
            
            if obj.blackboard.verbosity > 0
                fprintf('\n-------- [New Event] %s\n', evnt.EventName);
            end
            
            if ~obj.eventRegister.isKey(evnt.EventName)
                error('Unknown event in handleBlackboardEvent: %s', evnt.EventName);
            end
            ksList = obj.eventRegister(evnt.EventName);
            if length(ksList) < 1
                return;
            end
            % When several KSs should be triggered for an event, we sort
            % them based on importance ranking
            ranks = zeros(length(ksList));
            for n = 1:length(ksList)
                ks = ksList{n};
                ranks(n) = obj.rankKS(ks);
            end
            [~,idx] = sort(ranks, 'descend');
            sortedList = ksList(idx);
            for n = 1:length(sortedList)
                ks = sortedList{n};
                if isa(evnt,'BlackboardEventData')
                    ks.setActiveArgument(evnt.data);
                end
                if ks.canExecute
                    obj.addKSI(ks);
                end
            end
        end
    end
    
end
