classdef FactorialSourceModelKS < AuditoryFrontEndDepKS
    % FactorialSourceModelKS uses factorial source models to jointly 
    % estimate a mask for the target source

    % TODO: make this KS work with synthesized sound sources, see qoe_localisation folder
    % in TWOEARS/examples repo
    
    properties (SetAccess = private)
        blockSize                   % The size of one data block that
                                    % should be processed by this KS in
                                    % [s].
        dataPath = fullfile('learned_models', 'FactorialSourceModelKS');

        sourceGMMs;                 % source GMMs
        UBM;                        % universal background model
        sourceList;
        gmm_x;                      % Target GMM
        gmm_n;                      % Background GMM
        maskFloor = 0.4;            % Mask values below this floor are set to 0
        targetSource = [];
    end

    methods
        function obj = FactorialSourceModelKS(targetSource, sourcePreset)

            defaultFreqRange = [80 8000];
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
            
            % Load source GMMs
            if exist('targetSource', 'var')
                obj.targetSource = targetSource;
            else
                obj.targetSource = 'speech';
            end
            if ~exist('sourcePreset', 'var')
                sourcePreset = 'JIDO-REC';
            end
            
            strSourceGMMs = fullfile(obj.dataPath, sprintf('SourceGMMs_%s_ratemap.mat', sourcePreset));
            load(db.getFile(strSourceGMMs));

            obj.sourceGMMs = C.sourceGMMs;
            obj.sourceList = C.sourceList;
            obj.UBM = C.UBM;
            obj.gmm_x = C.UBM; % default no target
            obj.gmm_n = C.UBM;
            
        end

        function setTargetSource(obj, targetSource)
            obj.targetSource = targetSource;
            if isempty(targetSource)
                obj.gmm_x = obj.UBM;
            else
                obj.gmm_x = obj.sourceGMMs{strcmp(targetSource, obj.sourceList)};
            end
        end
        
        function setBackgroundSource(obj, bgSource)
            if isempty(bgSource)
                obj.gmm_n = obj.UBM;
            else
                obj.gmm_n = obj.sourceGMMs{strcmp(bgSource, obj.sourceList)};
            end
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
            
            % Estimate a mask using mixed observation and source GMMs
            mask = estimateMaskGmm(ratemap, obj.gmm_x, obj.gmm_n);
            
            % subplot(211); imagesc(ratemap); axis xy;
            % subplot(212); imagesc(mask); axis xy;

            %mask(mask<obj.maskFloor) = 0;

            afe = obj.getAFEdata;
            afe = afe(1);
                
            % Create a new source segregation hypothesis
            hyp = SourceSegregationHypothesis(mask, obj.targetSource, afe{1}.cfHz, 1/afe{1}.FsHz);
            obj.blackboard.addData( ...
                'sourceSegregationHypothesis', hyp, false, obj.trigger.tmIdx);
            notify(obj, 'KsFiredEvent', BlackboardEventData( obj.trigger.tmIdx ));
        end

        % Visualisation
        function visualise(obj)
            if ~isempty(obj.blackboardSystem.afeVis)
                hyp = obj.blackboard.getData( ...
                'sourceSegregationHypothesis', obj.trigger.tmIdx).data;
                obj.blackboardSystem.afeVis.drawMask(hyp.mask);
            end
        end
        
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
