classdef BlackboardMonitor < handle
    %AgendaManager
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        agenda;                % Agenda contains KSIs
        listeners;
        boundFromRegister;
        blackboard;
    end
    
    methods(Static)
    end
    
    methods
        function obj = BlackboardMonitor(bb)
            obj.listeners = {};
            obj.boundFromRegister = {};
            obj.blackboard = bb;
        end
        
        function bind( obj, sources, sinks, eventName )
            if nargin < 4, eventName = 'KsFiredEvent'; end;
            for src = sources
                src = src{1};
                for snk = sinks
                    snk = snk{1};
                    obj.listeners{end+1} = addlistener( src, eventName, ...
                        @(evntSrc, evnt)(obj.handleBinding( evntSrc, evnt, snk ) ) );
                    if ~isempty(obj.boundFromRegister)
                        snkIdxInBindRegister = cellfun(@(a)(eq(a,snk)),obj.boundFromRegister(:,1));
                    else
                        snkIdxInBindRegister = 0;
                    end
                    if sum( snkIdxInBindRegister ) == 0
                        obj.boundFromRegister{end+1,1} = snk;
                        obj.boundFromRegister{end,2} = src;
                    else
                        obj.boundFromRegister{snkIdxInBindRegister,2} = ...
                            [obj.boundFromRegister{snkIdxInBindRegister,2}, src];
                    end
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
        
        %   ks:     handle of KS that shall be focused on
        %   [propagateDown]:    if 1, KSs that ks depends on are also put
        %                       into focus
        function focusOn( obj, ks, propagateDown )
            if nargin < 3, propagateDown = 0; end;
            ks.focus();
            if propagateDown
                snkIdxInBindRegister = cellfun(@(a)(eq(a,ks)),obj.boundFromRegister(:,1));
                if sum( snkIdxInBindRegister ) >= 1
                    for boundFromKs = obj.boundFromRegister{snkIdxInBindRegister,2}
                        obj.focusOn( boundFromKs, 1 );
                    end
                end
            end
        end

        function resetFocus( obj )
            for ks = obj.blackboard.KSs
                ks{1}.resetFocus();
            end
        end
        
    end
    
end
