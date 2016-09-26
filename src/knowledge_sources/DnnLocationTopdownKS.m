classdef DnnLocationTopdownKS < AuditoryFrontEndDepKS
    % DnnLocationTopdownKS calculates posterior probabilities for each azimuth angle and
    % generates SourcesAzimuthsDistributionHypothesis when provided with spatial
    % observation

    % TODO: make this KS work with synthesized sound sources, see qoe_localisation folder
    % in TWOEARS/examples repo
    
    properties (SetAccess = private)
        angles;                     % All azimuth angles to be considered
        DNNs;                       % Learned deep neural networks
        normFactors;                % Feature normalisation factors
        nChannels;                  % Number of frequency channels
        dataPath = fullfile('learned_models', 'DnnLocationKS');
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
    end

    methods
        function obj = DnnLocationTopdownKS(preset, highFreq, lowFreq, azRes)
            if nargin < 1
                % Default preset is 'MCT-DIFFUSE'. For localisation in the
                % front hemifield only, use 'MCT-DIFFUSE-FRONT'
                preset = 'MCT-DIFFUSE';
            end
            defaultFreqRange = [80 8000];
            freqRange = defaultFreqRange;
            % Frequency range to be considered
            if exist('highFreq', 'var')   
                freqRange(2) = highFreq;
            end
            if exist('lowFreq', 'var')
                freqRange(1) = lowFreq;
            end
            if nargin < 4
                % Default azimuth resolution is 5 deg.
                azRes = 5;
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
            requests{1}.name = 'crosscorrelation';
            requests{1}.params = param;
            requests{2}.name = 'ild';
            requests{2}.params = param;
            requests{3}.name = 'ratemap';
            requests{3}.params = param;
            obj = obj@AuditoryFrontEndDepKS(requests);
            obj.blockSize = 0.5;
            obj.invocationMaxFrequency_Hz = 10;
            obj.nChannels = nChannels;
            obj.freqRange = freqRange;
            
            % Load localiastion DNNs
            obj.DNNs = cell(nChannels, 1);
            obj.normFactors = cell(nChannels, 1);

            nHiddenLayers = 2;
            for c = 1:nChannels
                strModels = sprintf( ...
                    '%s/LearnedDNNs_%s_ild-cc_%ddeg_%dchannels/DNN_%s_%ddeg_%dchannels_channel%d_%dlayers.mat', ...
                    obj.dataPath, preset, azRes, nChannels, preset, azRes, nChannels, c, nHiddenLayers);
                % Load localisation module
                load(db.getFile(strModels));
                obj.DNNs{c} = C.NNs;
                obj.normFactors{c} = C.normFactors;
            end
            obj.angles = C.azimuths;
            
            % Load source GMMs
            sourcePreset = 'QU_ANECHOIC';
            strSourceGMMs = fullfile('sourceGMMs', sprintf('Source_%s_ratemap', sourcePreset));
            load(strSourceGMMs);
            targetSource = 'target';

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
            %afeData = obj.getAFEdata();
            %timeSObj = afeData(3);
            %bExecute = hasSignalEnergy(timeSObj, obj.blockSize, obj.timeSinceTrigger);
            
            % Execute KS if a sufficient amount of data for one block has
            % been gathered
            bExecute = obj.hasEnoughNewSignal( obj.blockSize );
            bWait = false;
        end

        function execute(obj)
            cc = obj.getNextSignalBlock( 1, obj.blockSize, obj.blockSize, false );
            nlags = size(cc,3);
            if nlags > 37 % 37 lags when sampled at 16kHz
                error('DnnLocationKS: requires sampling rate to be 16kHz (set in AuditoryFrontEndKS)');
            end
            idx = ceil(nlags/2);
            mlag = 16; % only use -1 ms to 1 ms
            cc = cc(:,:,idx-mlag:idx+mlag);
            ild = obj.getNextSignalBlock( 2, obj.blockSize, obj.blockSize, false );

            ratemap = obj.getNextSignalBlock( 3, obj.blockSize, obj.blockSize, false );
            ratemap = (ratemap{1}' + ratemap{2}') ./ 2;
            % log compression
            ratemap = log(max(ratemap, eps));
                        
            % Only consider those channels within obj.freqRange
            if isempty(obj.channels)
                afe = obj.getAFEdata;
                obj.channels = find(afe(1).cfHz >= obj.freqRange(1) & afe(1).cfHz <= obj.freqRange(2));
            end
            
            % Estimate a mask using mixed observation and source GMMs
            mask = estimateMaskGmm(ratemap, obj.gmm_x, obj.gmm_n);
            % subplot(211); imagesc(ratemap); axis xy;
            % subplot(212); imagesc(mask); axis xy;
            mask = mask(obj.channels, :);
            mask(mask<obj.maskFloor) = 0;
            
            % Compute posterior distributions for each frequency channel and time frame
            [nFrames] = size(ild,1);
            nAzimuths = numel(obj.angles);
            numChans = length(obj.channels);
            post = zeros(nFrames, nAzimuths, numChans);
            yy = zeros(nFrames, nAzimuths);
            for n = 1:numChans
                ch = obj.channels(n);
                testFeatures = [ild(:,ch) squeeze(cc(:,ch,:))];

                % Normalise features
                testFeatures = testFeatures - ...
                    repmat(obj.normFactors{ch}(1,:),[size(testFeatures,1) 1]);
                testFeatures = testFeatures ./ ...
                    sqrt(repmat(obj.normFactors{ch}(2,:),[size(testFeatures,1) 1]));

                obj.DNNs{ch}.testing = 1;
                obj.DNNs{ch} = nnff(obj.DNNs{ch}, testFeatures, yy);
                post(:,:,n) = obj.DNNs{ch}.a{end} + eps;
                obj.DNNs{ch}.testing = 0;
            end

            % Integrate over time-frequency by applying the mask
            mask2 = reshape(mask', size(mask,2), 1, size(mask,1));

            % Integrate probabilities across all frequency channel
            prob_AF = exp(squeeze(nanSum(bsxfun(@times,log(post),mask2),3)));

            % Normalize such that probabilities sum up to one for each frame
            prob_AFN = transpose(prob_AF ./ repmat(sum(prob_AF,2),[1 nAzimuths]));

            % Integrate across all frames
            %prob_AFN_F = nanmean(prob_AFN,2);
            mask3 = sum(mask);
            prob_AFN_F = nanSum(bsxfun(@times,prob_AFN,mask3./sum(mask3)),2);
            
%             % Average posterior distributions over frequency
%             prob_AF = exp(squeeze(nanSum(log(post),3)));
% 
%             % Normalise each frame such that probabilities sum up to one
%             prob_AFN = prob_AF ./ repmat(sum(prob_AF,2),[1 nAzimuths]);
% 
%             % Average posterior distributions over time
%             prob_AFN_F = nanMean(prob_AFN, 1);

            % Create a new location hypothesis
            currentHeadOrientation = obj.blackboard.getLastData('headOrientation').data;
            aziHyp = SourcesAzimuthsDistributionHypothesis( ...
                currentHeadOrientation, obj.angles, prob_AFN_F);
            obj.blackboard.addData( ...
                'sourcesAzimuthsDistributionHypotheses', aziHyp, false, obj.trigger.tmIdx);
            notify(obj, 'KsFiredEvent', BlackboardEventData( obj.trigger.tmIdx ));
        end

    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
