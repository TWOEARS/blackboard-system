classdef IdentityLocationDecisionKS < AbstractKS
    
    properties (SetAccess = private)
        count = 0
        idMasksLoc % flag when set to true, location bins are masked by the identification decision
    end

    methods
        function obj = IdentityLocationDecisionKS(idMasksLoc)
            obj@AbstractKS();
            obj.setInvocationFrequency(4);
            if ~exist('idMasksLoc', 'var')
                obj.idMasksLoc = false;
            else
                obj.idMasksLoc = idMasksLoc;
            end
        end
        
        function setInvocationFrequency( obj, newInvocationFrequency_Hz )
            obj.invocationMaxFrequency_Hz = newInvocationFrequency_Hz;
        end
        
        function [b, wait] = canExecute( obj )
            b = true;
            wait = false;
        end
        
        function execute(obj)
            idloc = obj.blackboard.getData( ...
                'identityLocationHypotheses', ...
                obj.trigger.tmIdx).data;
            obj.count = 0;
            for ii = 1:numel(idloc)
                tmp = idloc(ii);
                if ~obj.idMasksLoc || tmp.d >= 1
                    locIdxs = find(tmp.azimuthDecisions>=1);
                    for locIdx = 1:numel(locIdxs)
                        hyp = IdentityHypothesis( tmp.label, ...
                            tmp.sourcesDistribution(locIdx), ...
                            1, ... # decision
                            tmp.concernsBlocksize_s, ...
                            tmp.azimuths(locIdx) );
                        obj.blackboard.addData( 'identityHypotheses', ...
                             hyp, true, obj.trigger.tmIdx );
                        obj.count = obj.count + 1;
                    end
                end
            end
            disp(obj.count)
            if obj.count > 0
                notify( obj, 'KsFiredEvent', BlackboardEventData( obj.trigger.tmIdx ) );
            end
        end
        
        function visualise(obj)
            if ~isempty(obj.blackboardSystem.locVis) && obj.count > 0
                idloc = obj.blackboard.getData( ...
                    'identityHypotheses', obj.trigger.tmIdx).data;
                obj.blackboardSystem.locVis.setLocationIdentity(...
                    {idloc(:).label}, {idloc(:).p}, {idloc(:).d}, {idloc(:).loc});
            end
        end
    end
end
