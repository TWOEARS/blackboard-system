classdef SchuitmanKS < AuditoryFrontEndDepKS
    % SEGMENTATIONKS This knowledge source computes soft or binary masks
    %   from a set of auditory features in the time frequency domain. The
    %   number of sound sources that should be segregated must be specified
    %   upon initialization. Each mask is associated with a corresponding
    %   estimate of the source position, given as Gaussian distributions.
    %   The segmentation stage can be initialized with additional prior
    %   information, if estimated of the positions of certain sound sources
    %   are available.
    %
    % AUTHOR:
    %   Christopher Schymura (christopher.schymura@rub.de)
    %   Cognitive Signal Processing Group
    %   Ruhr-Universitaet Bochum
    %   Universitaetsstr. 150, 44801 Bochum

    properties (SetAccess = private)
        name                        % Name of the KS instance
        blockSize                   % The size of one data block that
                                    % should be processed by this KS in
                                    % [s].
        fixedPositions = [];        % A set of positions that should be
                                    % fixed during the segmentation
                                    % process.
        bVerbose = false            % Display processing information?
        
        cfSplitMin = 168            % min. centre frequency for Clarity and Reverberance
        cfSplitMax = 1840           % max. centre frequency for Clarity and Reverberance
        cfITDMin = 387              % min. centre frequency for ITD fluctuation calculation 
        cfITDMax = 1840             % min. centre frequency for ITD fluctuation calculation 
        cfLowMin = 168              % min. centre frequency for low frequency level calculation
        cfLowMax = 387              % max. centre frequency for low frequency level calculation
        
        ASWalpha = 2E-2;
        ASWbeta = 5.63E+2;
        LEValpha = 2.76E-2;
        LEVbeta = 6.80E+2;
    end

    methods (Access = public)
        function obj = SchuitmanKS(name, varargin)
            % SCHUITMANKS This is the class constructor. This KS can
            %   either be initialized in working or training-mode. In
            %   working mode, the KS can be used within a working
            %   blackboard architecture. If set to training mode,
            %   localization models needed for the segmentation stage can
            %   be trained for a given set of HRTFs.
            %
            % REQUIRED INPUTS:
            %   name - Name that describes the properties of the
            %       instantiated KS object.
            %
            % OPTIONAL INPUTS:
            %   blockSize - Size of the processing blocks in [s]
            %       (default = 1).
            %   nSources - Number of sources that should be separated
            %       (default = 2).
            %   doBackgroundEstimation - Flag that indicates if an
            %       additional estimation of the background noise should be
            %       performed. If this function is enabled, an additional
            %       segmentation hypothesis will be generated at each
            %       execution of this KS, which contains a soft mask for
            %       the background (default = true);
            %
            % INPUT PARAMETERS:
            %   ['NumChannels', numChannels] - Name-value pair for setting
            %       the number of gammatone filterbank channels that should
            %       be used by the Auditory Front-End.
            %   ['FLow', fLow] - Name-value pair for setting the lowest
            %       center frequency of the gammatone filterbank in Hz.
            %   ['FHigh', fHigh] - Name-value pair for setting the highest
            %       center frequency of the gammatone filterbank in Hz.
            %   ['Verbosity', bVerbose] - Flag indicating wheter processing
            %       information should be displayed during runtime.

            % Check inputshypotheses
            p = inputParser();
            defaultNumChannels = 32;
            defaultWindowSize = 0.02;
            defaultHopSize = 0.01;
            defaultFLow = 80;
            defaultFHigh = 8000;
            defaultBlockSize = 1;
            defaultBVerbose = false;

            p.addRequired('name', @ischar);
            p.addOptional('blockSize', defaultBlockSize, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'real', 'scalar', 'nonnegative'}));
            p.addParameter('NumChannels', defaultNumChannels, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'integer', 'scalar', 'nonnegative'}));
            p.addParameter('FLow', defaultFLow, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'real', 'scalar', 'nonnegative'}));
            p.addParameter('FHigh', defaultFHigh, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'real', 'scalar', 'nonnegative'}));
            p.addParameter('WindowSize', defaultWindowSize, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'real', 'scalar', 'nonnegative'}));
            p.addParameter('HopSize', defaultHopSize, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'real', 'scalar', 'nonnegative'}));
            p.addParameter('Verbosity', defaultBVerbose, @islogical);
            p.parse(name, varargin{:});

            % Set parameters for the gammatone filterbank processor
            fb_type = 'gammatone';
            fb_lowFreqHz = p.Results.FLow;
            fb_highFreqHz = p.Results.FHigh;
            fb_nChannels = p.Results.NumChannels;
            
            % Set parameters for the ILD processor
            itd_wSizeSec = p.Results.WindowSize;
            itd_hSizeSec = p.Results.HopSize;
            itd_wname = 'hann';

            % Generate parameter structure
            afeParameters = genParStruct( ...
                'fb_type', fb_type, ...
                'fb_lowFreqHz', fb_lowFreqHz, ...
                'fb_highFreqHz', fb_highFreqHz, ...
                'fb_nChannels', fb_nChannels, ...
                'itd_wSizeSec', itd_wSizeSec, ...
                'itd_hSizeSec', itd_hSizeSec, ...
                'itd_wname', itd_wname);

            % Set AFE requests
            requests{1}.name = 'adaptation';
            requests{1}.params = afeParameters;
            requests{2}.name = 'itd';
            requests{2}.params = afeParameters;
            obj = obj@AuditoryFrontEndDepKS(requests);

            % Instantiate KS
            obj.name = p.Results.name;
            obj.blockSize = p.Results.blockSize;
            obj.bVerbose = p.Results.Verbosity;
            obj.lastExecutionTime_s = 0;
        end

        function [bExecute, bWait] = canExecute(obj)
            % CANEXECUTE This function specifies which conditions must be
            %   met before this KS can be executed.

            % Execute KS if a sufficient amount of data for one block has
            % been gathered
            bExecute = (obj.blackboard.currentSoundTimeIdx - ...
                obj.lastExecutionTime_s) >= obj.blockSize;
            bWait = false;
        end

        function execute(obj)          
            % set hypotheses from segmentation
            segHyp = obj.blackboard.getData( ...
                'segmentationHypotheses', obj.trigger.tmIdx).data;            
            aziHyp = obj.blackboard.getData( ...
                'sourceAzimuthHypotheses', obj.trigger.tmIdx).data;  
            % Get features of current signal block
            afeData = obj.getAFEdata();
            adapt = afeData(1);
            adapt_l = adapt{1}.getSignalBlock(obj.blockSize, ...
                obj.timeSinceTrigger);
            adapt_r = adapt{2}.getSignalBlock(obj.blockSize, ...
                obj.timeSinceTrigger);  
            itd = afeData(2).getSignalBlock(obj.blockSize, ...
                obj.timeSinceTrigger);
              
            % Some lengths and sizes  
            [nSamples, nChannels] = size(adapt_l);
            nSources = length(segHyp);
            fs = adapt{1}.FsHz;
            
            cf = adapt{1}.cfHz;
            % select frequency bands for Reverberance and Clarity calculation
            cfSplitSelect = cf >= obj.cfSplitMin & cf <= obj.cfSplitMax;
            cfSplitK = sum(cfSplitSelect);
            % select frequency bands for low frequency level calculation
            cfLowSelect = cf >= obj.cfLowMin & cf <= obj.cfLowMax;
            cfLowK = sum(cfLowSelect);
            % select frequency bands for ITD fluctuations
            cfITDSelect = cf >= obj.cfITDMin & cf <= obj.cfITDMax;
            
            % apply masks to generate streams
            adapt_seg_l = zeros([nSamples, nChannels, nSources]);
            adapt_seg_r = zeros([nSamples, nChannels, nSources]);  
            ITDstd = zeros(nSources,1);
            for k=1:nSources
              % resample soft mask and
              resSegHyp = interp1( ...
                (0.5:1:size(segHyp(k).softMask,1)-0.5)*segHyp(k).hopSize, ...
                segHyp(k).softMask, ...
                (0:1:nSamples-1)/fs, ...
                'nearest', ...
                0 ); 
              % apply on left and right ear channel
              adapt_seg_l(:,:,k) = resSegHyp.*adapt_l;
              adapt_seg_r(:,:,k) = resSegHyp.*adapt_r;
              % weighted standard deviation of ITD of all streams
              w = segHyp(k).softMask(:,cfITDSelect);
              W = sum(w(:));    
              ITDmean = sum(sum(w.*itd(:,cfITDSelect)))/W;
              ITDstd = sqrt( sum(w.*(itd(:,cfITDSelect)-ITDmean).^2)/W );
            end
            
            % compute Reverberance after Schuitman et al., (Eq. 11/12)
            ReverbHyp = 1/cfSplitK/nSamples.*sum(sum(sqrt(...
              adapt_seg_l(:,cfSplitSelect,1).^2 + adapt_seg_r(:,cfSplitSelect,1).^2 ...
              )));

            ClarityHyp = zeros(nSources-1, 1);
            ASWHyp = zeros(nSources-1,1);
            LEVHyp = zeros(nSources-1,1);
            for k=2:nSources
              % compute Clarity after Schuitman et al., (Eq. 14/15)
              ClarityHyp(k-1) = 1/cfSplitK/nSamples.*sum(sum(sqrt(...
                adapt_seg_l(:,cfSplitSelect,k).^2 + adapt_seg_r(:,cfSplitSelect,k).^2 ...
                )));
              % low frequency level
              LevelLow = 1/cfLowK/nSamples.*sum(sum(sqrt(...
                adapt_seg_l(:,cfLowSelect,k).^2 + adapt_seg_r(:,cfLowSelect,k).^2 ...
                )));
              % compute Apparent Source Width after Schuitman et al., (Eq. 18)
              ASWHyp(k-1) = obj.ASWalpha*LevelLow + ...
                log10(1+obj.ASWbeta*ITDstd(k)*10^3);
              % compute Listener Envelopment after Schuitman et al., (Eq. 23)
              LEVHyp(k-1) = obj.LEValpha*ReverbHyp + ...
                log10(1+obj.LEVbeta*ITDstd(1)*10^3);                              
            end
            
            % add data to blackboard
            obj.blackboard.addData('ReverberanceHypotheses', ...
              ReverbHyp, true, obj.trigger.tmIdx);
            obj.blackboard.addData('ClarityHypotheses', ...
              ClarityHyp, true, obj.trigger.tmIdx);
            obj.blackboard.addData('ASWHypotheses', ...
              ASWHyp, true, obj.trigger.tmIdx);
            obj.blackboard.addData('LEVHypotheses', ...
              LEVHyp, true, obj.trigger.tmIdx);
            
            % plotting  
            figure
            timescale = [0,nSamples/fs];
            freqscale = [1,nChannels]; 
            for k=1:nSources
              subplot (2, nSources, k)
              imagesc(timescale, freqscale, adapt_seg_l(:,:,k).');
%               title(sprintf('Estimated Azimuth: %3.2f deg', ...
%                 aziHyp(k).sourceAzimuth/pi*180));
              ylabel('Auditory Band');
              xlabel('time/s');
              subplot (2, nSources, nSources+k)
              imagesc(timescale, freqscale, adapt_seg_r(:,:,k).');
              ylabel('Auditory Band');
              xlabel('time/s');
            end
          
            % Trigger event that KS has been executed
            notify(obj, 'KsFiredEvent', ...
                BlackboardEventData(obj.trigger.tmIdx));
        end
    end
end
