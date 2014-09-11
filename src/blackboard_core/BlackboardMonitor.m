classdef BlackboardMonitor < handle
    %AgendaManager
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        agenda;                % Agenda contains KSIs
        listeners;
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
            obj.listeners = {};
            obj.blackboard = bb;
        end
        
        function bind( obj, sources, sinks, eventName )
            if nargin < 4, eventName = 'KsFiredEvent'; end;
            for src = sources
                for snk = sinks
                    obj.listeners{end+1} = addlistener( src{1}, eventName, ...
                        @(evntSrc, evnt)(obj.handleBinding( evntSrc, evnt, snk{1} ) ) );
                end
            end
        end
        
        function addKSI( obj, ks, currentSoundTimeIdx, triggerSource )
            ks.setActiveArgument( currentSoundTimeIdx );
            if ks.canExecute()
                ksi = KSInstantiation( ks, currentSoundTimeIdx, triggerSource );
                obj.agenda = [obj.agenda ksi];
            end
        end
        
        function handleBinding(obj, evntSource, evnt, evntSink )
            if obj.blackboard.verbosity > 0
                fprintf('\n-------- [New Event] %s\n', evnt.EventName);
            end
            obj.addKSI( evntSink, obj.blackboard.currentSoundTimeIdx, evntSource );
        end
    end
    
end
