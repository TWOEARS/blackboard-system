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
            p.addParameter('Verbosity', defaultBVerbose, @islogical);
            p.parse(name, varargin{:});

            % Set parameters for the gammatone filterbank processor
            fb_type = 'gammatone';
            fb_lowFreqHz = p.Results.FLow;
            fb_highFreqHz = p.Results.FHigh;
            fb_nChannels = p.Results.NumChannels;

            % Generate parameter structure
            afeParameters = genParStruct( ...
                'fb_type', fb_type, ...
                'fb_lowFreqHz', fb_lowFreqHz, ...
                'fb_highFreqHz', fb_highFreqHz, ...
                'fb_nChannels', fb_nChannels);

            % Set AFE requests
            requests{1}.name = 'adaptation';
            requests{1}.params = afeParameters;
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
            bExecute = true;
            bWait = false;
        end

        function execute(obj)
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
              
            % Get number of frames and channels
            [nFrames, nChannels] = size(adapt_l);
            fs = adapt{1}.FsHz;
            timescale = [0,nFrames/fs];
            freqscale = [1,nChannels];
            
            figure(1)
            subplot (2, 3, 1)
            imagesc(timescale, freqscale, adapt_l.');
            ylabel('Auditory Band');
            xlabel('time/s');
            subplot (2, 3, 2)
            imagesc(timescale, freqscale, adapt_r.');
            ylabel('Auditory Band');
            xlabel('time/s');
            
            for k=1:length(segHyp)
              subplot (2, 3, k+3)
              imagesc(timescale, freqscale, segHyp(k).softMask.');
              title(sprintf('Estimated Azimuth: %3.2f deg', ...
                aziHyp(k).sourceAzimuth/pi*180));
              ylabel('Auditory Band');
              xlabel('time/s');
            end
          
            % Trigger event that KS has been executed
            notify(obj, 'KsFiredEvent', ...
                BlackboardEventData(obj.trigger.tmIdx));
        end
    end
end
