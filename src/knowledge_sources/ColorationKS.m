classdef ColorationKS < AuditoryFrontEndDepKS
    % ColorationKS predicts the coloration of a signal compared to a learned reference
    % signal. If no reference is available the current signal will be stored as reference.
    %
    % The coloration is judged after the model from Moore and Tan (2004).

    properties (SetAccess = private)
        % The ColorationKS has different parameters for speech and noise/music and needs a
        % parameter to inform it about the presented audio type.
        % This should be replaced by an automatic classification of the audio type in the
        % future.
        audioType = '';
    end

    methods
        function obj = ColorationKS(audioType)
            param = genParStruct( ...
                'fb_type', 'gammatone', ...
                'fb_lowFreqHz', 25, ... % ERB number 1, (1) on page 901
                'fb_highFreqHz', 16800, ... % ERB number 40, (1) on page 901
                'fb_nERBs', 1, ...
                'fb_bwERBs', 1.01859/1.5); % final set of parameters on page 906
            requests{1}.name = 'filterbank';
            requests{1}.params = param;
            requests{2}.name = 'time';
            requests{2}.params = param;
            requests{3}.name = 'adaptation';
            requests{3}.params = param;
            obj = obj@AuditoryFrontEndDepKS(requests);
            % This KS stores it actual execution times
            obj.lastExecutionTime_s = 0;
            obj.audioType = audioType;
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
                if obj.blackboard.verbosity > 0
                    fprintf('--%05.2fs [ColorationKS:] Learning the reference.\n', ...
                            obj.trigger.tmIdx);
                end
                refExcitationPattern = obj.getExcitationPattern();
                obj.blackboard.addData('colorationReference', refExcitationPattern, ...
                    false, obj.trigger.tmIdx);
            else
                if obj.blackboard.verbosity > 0
                    fprintf('--%05.2fs [ColorationKS:] Found reference in memory.\n', ...
                            obj.trigger.tmIdx);
                end
                refExcitationPattern = refExcitationPattern.data;
                testExcitationPattern = obj.getExcitationPattern();
                colorationValue = colorationMooreTan2003(testExcitationPattern, ...
                                                         refExcitationPattern, ...
                                                         obj.audioType);
                obj.blackboard.addData('colorationHypotheses', colorationValue, ...
                    false, obj.trigger.tmIdx);
            end
            obj.lastExecutionTime_s = obj.trigger.tmIdx;
            notify(obj, 'KsFiredEvent', BlackboardEventData(obj.trigger.tmIdx));
        end

    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
