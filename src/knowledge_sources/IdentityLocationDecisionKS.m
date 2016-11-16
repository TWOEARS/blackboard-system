classdef IdentityLocationDecisionKS < AbstractKS
    
    properties (SetAccess = private)
    end

    methods
        function obj = IdentityLocationKS( modelName, modelDir )
            obj@AbstractKS();
            obj.setInvocationFrequency(4);
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
            for ii = 1:numel(idloc)
                tmp = idloc(ii);
                if tmp.d >= 1
                    locIdxs = find(tmp.azimuthDecisions>=1);
                    for locIdx = 1:numel(locIdxs)
                        hyp = IdentityHypothesis( tmp.label, ...
                            tmp.sourcesDistribution(locIdx), ...
                            1, ... # decision
                            obj.blockCreator.blockSize_s, ...
                            tmp.azimuths(locIdx) );
                        dstIdx = dstIdx+1;
                        obj.blackboard.addData( 'identityHypotheses', ...
                             hyp, true, obj.trigger.tmIdx );
                    end
                end
            end
        end
    end
end
