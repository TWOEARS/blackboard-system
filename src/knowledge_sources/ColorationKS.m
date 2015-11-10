classdef ColorationKS < AuditoryFrontEndDepKS
    % ColorationKS predicts the coloration of a signal compared ...

    properties (SetAccess = private)
        blockSizeSec;
    end

    methods
        function obj = ColorationKS()
            param = genParStruct( ...
                'fb_type', 'gammatone', ...
                'fb_lowFreqHz', 80, ...
                'fb_highFreqHz', 20000, ...
                'fb_nERBs', 1);
            requests{1}.name = 'filterbank';
            requests{1}.params = param;
            requests{2}.name = 'adaptation';
            requests{2}.params = param;
            requests{3}.name = 'time';
            requests{3}.params = param;
            obj = obj@AuditoryFrontEndDepKS(requests);
            % This KS stores it actual execution times
            obj.lastExecutionTime_s = 0;
        end

        function [bExecute, bWait] = canExecute(obj)
            % Execute KS if a sufficient amount of data for one block has
            % been gathered
            bExecute = (obj.blackboard.currentSoundTimeIdx - ...
                obj.lastExecutionTime_s) >= getSignalLength(obj);
            bWait = false;
        end

        function excitationPattern = getExcitationPattern(obj)
            afeData = obj.getAFEdata();
            afeFilterbank = afeData(1);
            excitationPattern = afeFilterbank{1}.getSignalBlock(getSignalLength(obj), ...
                obj.timeSinceTrigger);
        end

        function len = getSignalLength(obj)
            len = obj.blackboard.KSs{1}.robotInterfaceObj.LengthOfSimulation;
        end

        function execute(obj)
            % This looks first in the Blackboard if we have already data for a Coloration
            % reference. If not it calculates them first.
            % Otherwise it will compare the reference data with the current ones.
            refExcitationPattern = obj.blackboard.getLastData('colorationReference');
            if isempty(refExcitationPattern)
                refExcitationPattern = obj.getExcitationPattern();
                obj.blackboard.addData('colorationReference', refExcitationPattern, ...
                    false, obj.trigger.tmIdx);
            else
                refExcitationPattern = refExcitationPattern.data;
                testExcitationPattern = obj.getExcitationPattern();
                colorationValue = colorationMooreTan2003(testExcitationPattern, ...
                                                         refExcitationPattern);
                obj.blackboard.addData('colorationHypotheses', colorationValue, ...
                    false, obj.trigger.tmIdx);
            end
            obj.lastExecutionTime_s = obj.trigger.tmIdx;
            notify(obj, 'KsFiredEvent', BlackboardEventData(obj.trigger.tmIdx));
        end

    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
