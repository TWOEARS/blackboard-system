classdef BlackboardMonitor < handle
    %AgendaManager
    %   Detailed explanation goes here
    
    properties (SetAccess = {?Scheduler})
        pastAgenda;             % executed KSIs
        agenda;                 % to be executed KSIs
    end
    properties (SetAccess = private)
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
            obj.pastAgenda = KSInstantiation.empty;
            obj.agenda = KSInstantiation.empty;
        end
        
        %% function bind( obj, sources, sinks, allowDoubleTriggerings, eventName )
        %   binds each source KSs to each sink KSs by means of events.
        %   default behavior -> src event 'KsFiredEvent' triggers the sink KS.
        %
        %   sources:    cell array of source KSs
        %   sinks:      cell array of sink KSs
        %   [eventName]:    the name of the event of the src KSs that 
        %                   triggers the sink KSs. Default: 'KsFiredEvent'                               
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
        
        %%
        function handleBinding(obj, evntSource, evnt, evntSink )
            if obj.blackboard.verbosity > 0
                fprintf('\n-------- [New Event] %s\n', evnt.EventName);
            end
            if isa( evnt, 'BlackboardEventData' )
                evntTmIdx = evnt.data;
            else
                evntTmIdx = obj.blackboard.currentSoundTimeIdx;
            end
            ksiAlreadyTriggered = arrayfun( ...
                @(ksi)( ksi.ks == evntSink && ...
                ksi.triggerSrc == evntSource && ...
                strcmp( ksi.eventName, evnt.EventName ) ),...
                obj.agenda );
            newKsi = KSInstantiation( evntSink, evntTmIdx, evntSource, evnt.EventName );
            if ~evntSink.allowDoubleInvocation && sum( ksiAlreadyTriggered ) > 0
                obj.agenda(ksiAlreadyTriggered) = newKsi;
            else
                obj.agenda(end+1) = newKsi;
            end
        end
        
        %%
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
