classdef ColorationKS < AuditoryFrontEndDepKS
    % ColorationKS predicts the coloration of a signal compared ...

    properties (SetAccess = private)
        auditoryFrontEndParameter;
    end

    methods
        function obj = ColorationKS()
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
            requests.r{2} = 'adaptation';
            requests.p{2} = param;
            requests.r{3} = 'time';
            requests.p{3} = param;
            obj = obj@AuditoryFrontEndDepKS(requests, blocksize_s);
            obj.auditoryFrontEndParameter = param;
        end

        function [bExecute, bWait] = canExecute(obj)
            signal = obj.getAuditoryFrontEndRequest(3); % get time signal
            bExecute = hasSignalEnergy(signal);
            bWait = false;
        end

        function execute(obj)
            %TODO:
            % In order to implement this KS the following prolbem has to be solved in
            % order to allow a comparison between the actual test signal and a reference
            % signal:
            % * two instances of the Binaural Simulator and the AFE has to be running in
            %   parallel
            % * both of them have to get the same commands for turning their head etc.
            error('ColorationKS functionality has to be implemented.');
            obj.blackboard.addData('colorationHypotheses', colorationValue, false, ...
                obj.trigger.tmIdx);
            notify(obj, 'KsFiredEvent', BlackboardEventData(obj.trigger.tmIdx));
        end

    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
