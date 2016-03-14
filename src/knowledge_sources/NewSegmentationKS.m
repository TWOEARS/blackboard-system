classdef NewSegmentationKS < AuditoryFrontEndDepKS
    % NEWSEGMENTATIONKS
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
        nSources                    % Number of sources that should be
                                    % separated.
        bVerbose = false            % Display processing information?
        dataPath = ...              % Path for storing trained models
            fullfile('learned_models', 'SegmentationKS');
    end

    methods (Access = public)
        function obj = NewSegmentationKS(name, varargin)
            % SEGMENTATIONKS Class constructor.
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
            %
            % INPUT PARAMETERS:
            %   ['NumChannels', numChannels] - Name-value pair for setting
            %       the number of gammatone filterbank channels that should
            %       be used by the Auditory Front-End.
            %   ['WindowSize', windowSize] - Name-value pair for setting
            %       the size of the processing window in seconds.
            %   ['HopSize', hopSize] - Name-value pair for setting the hop
            %       size or window shift in seconds that should be used
            %       during processing.
            %   ['FLow', fLow] - Name-value pair for setting the lowest
            %       center frequency of the gammatone filterbank in Hz.
            %   ['FHigh', fHigh] - Name-value pair for setting the highest
            %       center frequency of the gammatone filterbank in Hz.
            %   ['Verbosity', bVerbose] - Flag indicating wheter processing
            %       information should be displayed during runtime.

            % Check inputs
            p = inputParser();
            defaultNumChannels = 32;
            defaultWindowSize = 0.02;
            defaultHopSize = 0.01;
            defaultFLow = 80;
            defaultFHigh = 8000;
            defaultBVerbose = false;
            defaultBlockSize = 1;
            defaultNSources = 2;

            p.addRequired('name', @ischar);
            p.addOptional('blockSize', defaultBlockSize, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'real', 'scalar', 'nonnegative'}));
            p.addOptional('nSources', defaultNSources, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'integer', 'scalar', 'nonnegative'}));
            p.addParameter('NumChannels', defaultNumChannels, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'integer', 'scalar', 'nonnegative'}));
            p.addParameter('WindowSize', defaultWindowSize, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'real', 'scalar', 'nonnegative'}));
            p.addParameter('HopSize', defaultHopSize, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'real', 'scalar', 'nonnegative'}));
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

            % Set parameters for the cross-correlation processor
            cc_wSizeSec = p.Results.WindowSize;
            cc_hSizeSec = p.Results.HopSize;
            cc_wname = 'hann';

            % Set parameters for the ILD processor
            ild_wSizeSec = p.Results.WindowSize;
            ild_hSizeSec = p.Results.HopSize;
            ild_wname = 'hann';

            % Generate parameter structure
            afeParameters = genParStruct( ...
                'fb_type', fb_type, ...
                'fb_lowFreqHz', fb_lowFreqHz, ...
                'fb_highFreqHz', fb_highFreqHz, ...
                'fb_nChannels', fb_nChannels, ...
                'cc_wSizeSec', cc_wSizeSec, ...
                'cc_hSizeSec', cc_hSizeSec, ...
                'cc_wname', cc_wname, ...
                'ild_wSizeSec', ild_wSizeSec, ...
                'ild_hSizeSec', ild_hSizeSec, ...
                'ild_wname', ild_wname);

            % Set AFE requests
            requests{1}.name = 'crosscorrelation';
            requests{1}.params = afeParameters;
            requests{2}.name = 'ild';
            requests{2}.params = afeParameters;
            obj = obj@AuditoryFrontEndDepKS(requests);

            % Instantiate KS
            obj.name = p.Results.name;
            obj.blockSize = p.Results.blockSize;
            obj.nSources = p.Results.nSources;
            obj.bVerbose = p.Results.Verbosity;
            obj.lastExecutionTime_s = 0;

            % Check if trained models are available
            filename = [obj.name, '_models_', ...
                cell2mat(obj.reqHashs), '.mat'];
            try
                % Load available models and add them to object props
                models = load(xml.dbGetFile(fullfile(obj.dataPath, ...
                    obj.name, filename)));
            catch
                error(['No trained models are available for this ', ...
                       'KS. Please ensure to run KS training first.']);
            end
            obj.localizationModels = models.locModels;
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
            % EXECUTE This mehtods performs joint source segregation and
            %   localization for one block of audio data.

            % Get features of current signal block
            afeData = obj.getAFEdata();
            iacc = afeData(1).getSignalBlock(obj.blockSize, ...
                obj.timeSinceTrigger);
            ilds = afeData(2).getSignalBlock(obj.blockSize, ...
                obj.timeSinceTrigger);

            % Get number of frames and channels
            [nFrames, nChannels] = size(ilds);
            
            % TODO: Perform segmentation processing here...

            % Trigger event that KS has been executed
            notify(obj, 'KsFiredEvent', ...
                BlackboardEventData(obj.trigger.tmIdx));
        end

        function generateTrainingData(obj, pathToDatabase, ...
                sceneDescription)
            % GENERATETRAININGDATA This function generates a dataset
            %   containing ratemap features for different sound classes.
            %
            % REQUIRED INPUTS:
            %   pathToDatabase - Path to sound database that should be used
            %       for generating training data.
            %   sceneDescription - Scene description file in XML-format,
            %       that will be used by the Binaural Simulator to create
            %       binaural signals.

            % Check inputs
            p = inputParser();
            
            p.addRequired('pathToDatabase', @(x) exist(x, 'dir'));
            p.addRequired('sceneDescription', @(x) exist(x, 'file'));
            p.parse(sceneDescription);

            % Check if folder for storing training data exists
            dataFolder = fullfile(obj.dataPath, obj.name, 'data');
            if ~exist(dataFolder, 'dir')
                mkdir(dataFolder)
            end

            % Check if training data has already been generated
            filelist = getFiles(dataFolder, 'mat');
            if ~isempty(filelist)
                warning(['Training data for current KS is already ', ...
                    'available. Please run the ', ...
                    '''removeTrainingData()'' method before generating ', ...
                    'a new training dataset.']);
            else
                % TODO: Generate training data here...

            end
        end

        function removeTrainingData(obj)
            % REMOVETRAININGDATA Training data that has already been
            %   generated for a specific instance of this knowledge source
            %   can be removed via this function.

            % Check if folder containing training data exists
            trainingFolder = fullfile(obj.dataPath, obj.name, 'data');
            if ~exist(trainingFolder, 'dir')
                error(['No folder containing training data can be ', ...
                    'found for SegmentaionKS of type ', obj.name, '.']);
            end

            % Get all mat-files from training folder
            filelist = getFiles(trainingFolder, 'mat');
            if isempty(filelist)
                error([trainingFolder, ' does not contain any ', ...
                    'training files.']);
            end

            % Delete all files
            nFiles = length(filelist);

            for fileIdx = 1 : nFiles
                if obj.bVerbose
                    disp(['Deleting temporary training files (', ...
                        num2str(fileIdx), '/', num2str(nFiles), ') ...']);
                end

                % Get current filename
                filename = filelist{fileIdx};

                % Delete file
                delete(fullfile(trainingFolder, filename));
            end
        end

        function obj = train(obj, varargin)
            % TRAIN ...
            %
            % OPTIONAL INPUTS:
            %   bOverwrite - Flag that indicates if an existing model file
            %       that has already been genereated for the same parameter
            %       set should be overwritten by a retrained model
            %       (default = false).

            % Check inputs
            p = inputParser();
            defaultOverwrite = false;

            p.addOptional('bOverwrite', defaultOverwrite, @islogical);
            p.parse(varargin{:});

            % Check if folder containing training data exists
            trainingFolder = fullfile(obj.dataPath, obj.name, 'data');
            if ~exist(trainingFolder, 'dir')
                error(['No folder containing training data can be ', ...
                    'found for SegmentaionKS of type ', obj.name, '.']);
            end

            % Get all mat-files from training folder
            filelist = getFiles(trainingFolder, 'mat');
            if isempty(filelist)
                error([trainingFolder, ' does not contain any ', ...
                    'training files. Please run the method ', ...
                    '''generateTrainingData()'' first.']);
            end

            % Check if trained models for current parameter settings
            % already exist. Otherwise start training.
            filename = [obj.name, '_models_', cell2mat(obj.reqHashs), ...
                '.mat'];
            if exist(fullfile(obj.dataPath, obj.name, filename), ...
                    'file') && ~p.Results.bOverwrite
                error(['File containing trained models already exists ', ...
                    'for the current parameter settings. Please set ', ...
                    'this function in overwriting-mode to re-train ', ...
                    'the existing models.']);
            else
                % Get number of training files
                nFiles = length(filelist);

                % TODO: Add training script here...
            end
        end

        function obj = setBlockSize(obj, blockSize)
            % SETBLOCKSIZE Setter function for the block size.
            %
            % REQUIRED INPUTS:
            %   blockSize - Size of the processing blocks in [s].

            % Check inputs
            p = inputParser();

            p.addRequired('blockSize', @(x) validateattributes(x, ...
                {'numeric'}, {'real', 'scalar', 'nonnegative'}));
            p.parse(blockSize);

            % Set property
            obj.blockSize = blockSize;
        end

        function obj = setNumSources(obj, nSources)
            % SETNUMSOURCES Setter function for the number of sources.
            %
            % REQUIRED INPUTS:
            %   nSources - Number of sound sources.

            % Check inputs
            p = inputParser();

            p.addRequired('blockSize', @(x) validateattributes(x, ...
                {'numeric'}, {'integer', 'scalar', 'nonnegative'}));
            p.parse(nSources);

            % Set property
            obj.nSources = nSources;
        end
    end
end
