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
    
    % Parameters for Direct-Reverberant-Segmentation
    MU = 7.49*10^-3;
    MUdip = -1.33*10^-3;
    Tmin = 63.1/1000;
    
    % Parameters for Considered Frequency Bands
    cfSplitMin = 168            % min. centre frequency for Clarity and Reverberance
    cfSplitMax = 1840           % max. centre frequency for Clarity and Reverberance
    cfITDMin = 387              % min. centre frequency for ITD fluctuation calculation
    cfITDMax = 1840             % min. centre frequency for ITD fluctuation calculation
    cfLowMin = 168              % min. centre frequency for low frequency level calculation
    cfLowMax = 387              % max. centre frequency for low frequency level calculation
    
    % Parameters for Computing Apparent Source Width (ASW) and Listener
    % Envelopement (LEV)
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
      bExecute = obj.hasEnoughNewSignal( obj.blockSize );
      bWait = false;
    end
    
    function execute(obj)
      % Get features of current signal block
      afeData = obj.getAFEdata();
      adapt = afeData(1);
      adaptL = adapt{1}.getSignalBlock(obj.blockSize, ...
        obj.timeSinceTrigger);
      adaptR = adapt{2}.getSignalBlock(obj.blockSize, ...
        obj.timeSinceTrigger);
      itd = afeData(2).getSignalBlock(obj.blockSize, ...
        obj.timeSinceTrigger);
      itd(end,:) = [];
      
      % === Some lengths, sizes, and selections ===
      fs = adapt{1}.FsHz;
      cf = adapt{1}.cfHz;
      % select frequency bands for Reverberance and Clarity calculation
      cfSplitSelect = cf >= obj.cfSplitMin & cf <= obj.cfSplitMax;
      % select frequency bands for low frequency level calculation
      cfLowSelect = cf >= obj.cfLowMin & cf <= obj.cfLowMax;
      % select frequency bands for ITD fluctuations
      cfITDSelect = cf >= obj.cfITDMin & cf <= obj.cfITDMax;
      
      % Convolve with 20ms 1st order low pass
      Wn = (1000/20) / (fs/2);
      [b,a] = butter(1, Wn, 'low');
      YL = zeros(size(adaptL));
      YR = YL;
      for jj=1:length(cf)
        YL(:, jj) = filter(b, a, adaptL(:, jj));
        YR(:, jj) = filter(b, a, adaptR(:, jj));
      end
      
      % === Compute direct and reverberant Stream ===
      dirSegL = false(size(YL));
      dirSegR = dirSegL;
      revSegL = dirSegL;
      revSegR = dirSegL;

      dirYL = zeros(size(YL));
      dirYR = dirYL;
      revYL = dirYL;
      revYR = dirYL;
      
      for jj=1:length(cf)
        [dirYL(:,jj), revYL(:,jj), dirSegL(:,jj), revSegL(:,jj)] = ...
          obj.splitForegroundBackgroundSignal(YL(:,jj), fs);
        [dirYR(:,jj), revYR(:,jj), dirSegR(:,jj), revSegR(:,jj)] = ...
          obj.splitForegroundBackgroundSignal(YR(:,jj), fs);
      end
      
      % === ITD fluctuaction ===
      
      % weighted standard deviation of sources stream
      w = interp1((0:size(dirSegL,1)-1)/fs, double(dirSegL(:,cfITDSelect)), ...
        (0:size(itd,1)-1)*0.01+0.005, 'nearest');
      W = sum(w(:));
      dirItdMean = sum(sum(w.*itd(:,cfITDSelect)))/W;
      dirItdStd = sqrt( sum(w.*(itd(:,cfITDSelect)-dirItdMean).^2)/W );
      % weighted standard deviation of background stream
      w = interp1((0:size(revSegL,1)-1)/fs, double(revSegL(:,cfITDSelect)), ...
        (0:size(itd,1)-1)*0.01+0.005, 'nearest');
      W = sum(w(:));
      revItdMean = sum(sum(w.*itd(:,cfITDSelect)))/W;
      revItdStd = sqrt(sum(w.*(itd(:,cfITDSelect)-revItdMean).^2)/W );
      
      % === Compute Features ===
      
      % compute Reverberance after Schuitman et al., (Eq. 11/12)
      ReverbHyp = mean(mean(sqrt( revYL(:,cfSplitSelect).^2 ...
        + revYR(:,cfSplitSelect).^2 )));
      % compute Clarity after Schuitman et al., (Eq. 14/15)
      ClarityHyp = mean(mean(sqrt( dirYL(:,cfSplitSelect).^2 ...
        + dirYR(:,cfSplitSelect).^2 )));
      % low frequency level
      LevelLow = mean(mean(sqrt(...
        dirYL(:,cfLowSelect).^2 + dirYR(:,cfLowSelect).^2 ...
        )));
      % compute Apparent Source Width after Schuitman et al., (Eq. 18)
      ASWHyp = obj.ASWalpha*LevelLow + log10(1+obj.ASWbeta*dirItdStd*10^3);
      % compute Listener Envelopment after Schuitman et al., (Eq. 23)
      LEVHyp = obj.LEValpha*ReverbHyp + log10(1+obj.LEVbeta*revItdStd*10^3);
      
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
      [nSamples, nChannels] = size(dirYL);
      timescale = [0,nSamples/fs];
      freqscale = [1,nChannels];
      
      subplot(3, 2, 1)
      imagesc(timescale, freqscale, dirSegL.');
      subplot(3, 2, 3)
      imagesc(timescale, freqscale, dirYL.');
      subplot(3, 2, 5)% Positive and negative splitting thresholds
      imagesc(timescale, freqscale, dirYR.');
      subplot(3, 2, 2)
      imagesc(timescale, freqscale, revSegL.');
      subplot(3, 2, 4)
      imagesc(timescale, freqscale, revYL.');
      subplot(3, 2, 6)
      imagesc(timescale, freqscale, revYR.');
      
      for k=1:6
        subplot(3, 2, k)
        ylabel('Auditory Band');
        xlabel('time/s');
      end
      
      % Trigger event that KS has been executed
      notify(obj, 'KsFiredEvent', ...
        BlackboardEventData(obj.trigger.tmIdx));
    end
    function [sigForeground, sigBackground, idxForground, idxBackground] = splitForegroundBackgroundSignal(obj, sig, fs)
      %splitForegroundBackgroundSignal returns a forground and background signal
      %stream
      %
      %   USAGE
      %       [sigForeground, sigBackground, idxForground, idxBackground] = ...
      %           splitForegroundBackgroundSignal(sig, fs);
      %
      %   INPUT PARAMETERS
      %       sig         - signal to be splitted, this should be a low passed
      %                     filtered signal processed by the adaptation processor of
      %                     the Two!Ears Auditory Front-End
      %       fs          - Sampling arte / Hz
      %
      %   OUTPUT PARAMETERS
      %       sigForeground   - forground signal
      %       sigBackground   - background signal
      %       idxForground    - index of signal parts belonging to foreground
      %       idxBackground   - index of signal parts belonging to background
      %
      %   DETAILS
      %       The splitting into forground and background is implememted after van
      %       Dorp Schuitman et al., "Deriving content-specific measures of room
      %       acoustic perception using a binaural, nonlinear auditory model," JASA
      %       133, p. 1572-1585, 2013.
      
      % Positive and negative splitting thresholds
      Ymin = obj.MU * mean(abs(sig));
      Ymindip = obj.MUdip * mean(abs(sig));
      Nmin = obj.Tmin*fs;

      sigForeground = sig;
      sigBackground = sig;
      
      % === Positive signal part ===
      % Find signal parts above the positive threshold
      idx = sig > Ymin;
      % Find parts above the threshold for a period of Tmin
      idxForgroundPositive = obj.thresholdForSomeTime(idx, Nmin);
      
      % === Negative signal part ===
      % Find signal parts below the negative threshold
      idx = sig < Ymindip;
      % Find parts below the threshold for a period of Tmin
      idxForgroundNegative = obj.thresholdForSomeTime(idx, Nmin);
      
      % === Combine parts ===
      idxForground = idxForgroundPositive | idxForgroundNegative;
      idxBackground = not(idxForground);
      sigForeground(idxBackground) = 0;
      sigBackground(idxForground) = 0;      
    end
    function mask = thresholdForSomeTime(obj,mask, N)
      idx = find(mask);
      a = diff(idx');
      idx_end = find([a inf]>1); % end points
      idx_start = [1 idx_end(1:end-1)+1]; % start points
      c = diff([0 idx_end]); % length of parts
      % Remove all idx entries below a length of N
      idx_min = c>N;
      idx_end = idx_end(idx_min);
      idx_start = idx_start(idx_min);
      idx_new = [];
      for ii=1:length(idx_end)
        idx_new = [idx_new idx_start(ii):idx_end(ii)];
      end
      idx = idx(idx_new);
      mask = false(size(mask));
      mask(idx) = true;
    end
  end
end
