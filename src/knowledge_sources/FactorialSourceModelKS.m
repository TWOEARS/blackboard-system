classdef FactorialSourceModelKS < AuditoryFrontEndDepKS
    % FactorialSourceModelKS uses factorial source models to jointly 
    % estimate a mask for the target source

    % TODO: make this KS work with synthesized sound sources, see qoe_localisation folder
    % in TWOEARS/examples repo
    
    properties (SetAccess = private)
        nChannels;                  % Number of frequency channels
        blockSize                   % The size of one data block that
                                    % should be processed by this KS in
                                    % [s].
        energyThreshold = 2E-3;     % ratemap energy threshold (cuberoot 
                                    % compression) for detecting active 
                                    % frames
        freqRange;                  % Frequency range to be considered
        channels = [];              % Frequency channels to be used
        gmm_x;                      % Target GMM
        gmm_n;                      % Noise GMM
        maskFloor = 0.5;            % Mask values below this floor are set to 0
        targetSource;
    end

    methods
        function obj = FactorialSourceModelKS(targetSource, highFreq, lowFreq)
            

            defaultFreqRange = [80 8000];
            freqRange = defaultFreqRange;
            % Frequency range to be considered
            if exist('highFreq', 'var')   
                freqRange(2) = highFreq;
            end
            if exist('lowFreq', 'var')
                freqRange(1) = lowFreq;
            end
            nChannels = 32;
            param = genParStruct(...
                'fb_type', 'gammatone', ...
                'fb_lowFreqHz', defaultFreqRange(1), ...
                'fb_highFreqHz', defaultFreqRange(2), ...
                'fb_nChannels', nChannels, ...
                'ihc_method', 'halfwave', ...
                'ild_wSizeSec', 20E-3, ...
                'ild_hSizeSec', 10E-3, ...
                'rm_wSizeSec', 20E-3, ...
                'rm_hSizeSec', 10E-3, ...
                'rm_scaling', 'power', ...
                'rm_decaySec', 8E-3, ...
                'cc_wSizeSec', 20E-3, ...
                'cc_hSizeSec', 10E-3, ...
                'cc_wname', 'hann');
            requests{1}.name = 'ratemap';
            requests{1}.params = param;
            obj = obj@AuditoryFrontEndDepKS(requests);
            obj.blockSize = 0.5;
            obj.invocationMaxFrequency_Hz = 10;
            obj.nChannels = nChannels;
            obj.freqRange = freqRange;
            
            % Load source GMMs
            if exist('targetSource', 'var')
                obj.targetSource = targetSource;
            else
                obj.targetSource = 'target';
            end
            
            sourcePreset = 'QU_ANECHOIC';
            strSourceGMMs = fullfile('sourceGMMs', sprintf('Source_%s_ratemap', sourcePreset));
            load(strSourceGMMs);

            obj.gmm_x = C.sourceGMMs{strcmp(targetSource,C.sourceList)};

            % Load the specific source model
%              strResult = strcat(strResult, '_interfererKnown');
%              gmm_n = C.sourceGMMs{strcmp(interfererSource,C.sourceList)};

            % Pool all interferer models to form a universal background model
            gmms_interferer = C.sourceGMMs(strcmp(targetSource,C.sourceList)==0);
            gmm_n = gmms_interferer{1};
            for n = 2:numel(gmms_interferer)
                gmm_n.ncentres = gmm_n.ncentres + gmms_interferer{n}.ncentres;
                gmm_n.priors = [gmm_n.priors gmms_interferer{n}.priors];
                gmm_n.centres = [gmm_n.centres; gmms_interferer{n}.centres];
                gmm_n.covars = [gmm_n.covars; gmms_interferer{n}.covars];
            end
            gmm_n.priors = gmm_n.priors ./ sum(gmm_n.priors);
            gmm_n.nwts = gmm_n.ncentres + gmm_n.ncentres*gmm_n.nin*2;
            obj.gmm_n = gmm_n;
        end


        function [bExecute, bWait] = canExecute(obj)
            % Execute KS if a sufficient amount of data for one block has
            % been gathered
            bExecute = obj.hasEnoughNewSignal( obj.blockSize );
            bWait = false;
        end

        function execute(obj)
            ratemap = obj.getNextSignalBlock( 1, obj.blockSize, obj.blockSize, false );
            ratemap = (ratemap{1}' + ratemap{2}') ./ 2;
            % log compression
            ratemap = log(max(ratemap, eps));
                        
            % Only consider those channels within obj.freqRange
            if isempty(obj.channels)
                afe = obj.getAFEdata;
                afe = afe(1);
                obj.channels = find(afe{1}.cfHz >= obj.freqRange(1) & afe{1}.cfHz <= obj.freqRange(2));
            end
            
            % Estimate a mask using mixed observation and source GMMs
            mask = estimateMaskGmm(ratemap, obj.gmm_x, obj.gmm_n);
            % subplot(211); imagesc(ratemap); axis xy;
            % subplot(212); imagesc(mask); axis xy;
            mask = mask(obj.channels, :);
            mask(mask<obj.maskFloor) = 0;
            
            % Create a new source segregation hypothesis
            hyp = SourceSegregationHypothesis(mask, obj.targetSource);
            obj.blackboard.addData( ...
                'sourceSegregationHypothesis', hyp, false, obj.trigger.tmIdx);
            notify(obj, 'KsFiredEvent', BlackboardEventData( obj.trigger.tmIdx ));
        end

    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
