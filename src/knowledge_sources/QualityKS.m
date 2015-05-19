classdef QualityKS < AuditoryFrontEndDepKS
    % QualityKS predicts a MOS value for te given signal.
    %
    % At the moment this is only a dummy implementation that will always return 5.
    %
    % In the long run most probably this function will compare two signals and judge which
    % of the two has higher audio quality

    properties (SetAccess = private)
        auditoryFrontEndParameter;
    end

    methods
        function obj = QualityKS()
            % TODO: check what a meaningful block size looks like for quality
            blocksize_s = 0.5;
            param = genParStruct( ...
                'fb_type', 'gammatone', ...
                'fb_lowFreqHz', 80, ...
                'fb_highFreqHz', 20000, ...
                'fb_nERBs', 1, ...
                'ihc_method', 'breebart', ...
                'adpt_model', 'adt_dau');
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
            qualityValue = 5;
            warning('QualityKS functionality has to be implemented.');
            obj.blackboard.addData('qualityHypotheses', qualityValue, false, ...
                obj.trigger.tmIdx);
            notify(obj, 'KsFiredEvent', BlackboardEventData(obj.trigger.tmIdx));
        end

    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
