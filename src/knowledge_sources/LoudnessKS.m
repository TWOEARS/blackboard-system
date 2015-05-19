classdef LoudnessKS < AuditoryFrontEndDepKS
    % LoudnessKS predicts the loudness of a signal
    %
    % At the moment only a basic version is available which simply applies Zwickers
    % formula.

    properties (SetAccess = private)
        auditoryFrontEndParameter;
    end

    methods
        function obj = LoudnessKS()
            blocksize_s = 0.5;
            param = genParStruct( ...
                'fb_type', 'gammatone', ...
                'fb_lowFreqHz', 80, ...
                'fb_highFreqHz', 20000, ...
                'fb_nERBs', 1);
            requests.r{1} = 'filterbank';
            requests.p{1} = param;
            requests.r{2} = 'time';
            requests.p{2} = param;
            obj = obj@AuditoryFrontEndDepKS(requests, blocksize_s);
            obj.auditoryFrontEndParameter = param;
        end

        function [bExecute, bWait] = canExecute(obj)
            signal = obj.getAuditoryFrontEndRequest(2); % get time signal
            bExecute = hasSignalEnergy(signal);
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
