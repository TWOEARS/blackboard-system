classdef LoudnessKS < AuditoryFrontEndDepKS
    % LoudnessKS predicts the loudness of a signal
    %
    % At the moment only a basic version is available which simply applies Zwickers
    % formula.

    properties (SetAccess = private)
        auditoryFrontEndParameter;
        blocksize_s;
    end

    methods
        function obj = LoudnessKS()
            obj.blocksize_s = 0.5;
            param = genParStruct( ...
                'fb_type', 'gammatone', ...
                'fb_lowFreqHz', 80, ...
                'fb_highFreqHz', 20000, ...
                'fb_nERBs', 1);
            requests{1}.name = 'filterbank';
            requests{1}.params = param;
            requests{2}.name = 'time';
            requests{2}.params = param;
            obj = obj@AuditoryFrontEndDepKS(requests);
            obj.auditoryFrontEndParameter = param;
        end

        function [bExecute, bWait] = canExecute(obj)
            afeData = obj.getAFEdata();
            timeSObj = afeData('time');
            bExecute = hasSignalEnergy(timeSObj, obj.blocksize_s, obj.timeSinceTrigger);
            bWait = false;
        end

        function execute(obj)
            loudnessPower = 0.46; % Zwicker formula
            signal = obj.getAuditoryFrontEndRequest(1);
            signal = sign(signal) .* abs(signal).^loudnessPower;
            obj.blackboard.addData('loudnessHypotheses', signal, false, ...
                obj.trigger.tmIdx);
            notify(obj, 'KsFiredEvent', BlackboardEventData(obj.trigger.tmIdx));
        end

    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
