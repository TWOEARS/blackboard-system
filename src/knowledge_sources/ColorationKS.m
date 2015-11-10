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
            % Get length of block size from length of binaural simulation
            %obj
            %obj.blockSizeSec = obj.blackboard.robotConnect.LengthOfSimulation;
            % This KS stores it actual execution times
            obj.lastExecutionTime_s = 0;
        end

        function [bExecute, bWait] = canExecute(obj)
            %afeData = obj.getAFEdata();
            %timeSObj = afeData(3);
            %bExecute = hasSignalEnergy(timeSObj, obj.blockSizeSec, obj.timeSinceTrigger);
            %bWait = false;
            % Execute KS if a sufficient amount of data for one block has
            % been gathered
            bExecute = (obj.blackboard.currentSoundTimeIdx - ...
                obj.lastExecutionTime_s) >= getSignalLength(obj);
            if ~bExecute, disp('Wait'); end
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
            %TODO:
            % In order to implement this KS the following prolbem has to be solved in
            % order to allow a comparison between the actual test signal and a reference
            % signal:
            % * two instances of the Binaural Simulator and the AFE has to be running in
            %   parallel
            % * both of them have to get the same commands for turning their head etc.
            refExcitationPattern = obj.blackboard.getLastData('colorationReference')
            if isempty(refExcitationPattern)
                refExcitationPattern = obj.getExcitationPattern();
                obj.blackboard.addData('colorationReference', refExcitationPattern, ...
                    false, obj.trigger.tmIdx);
            else
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
