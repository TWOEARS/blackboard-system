classdef SegmentationKS < AuditoryFrontEndDepKS
    % SEGMENTATIONKS This knowledge source computes soft or binary masks
    %   from a set of auditory features in the time frequency domain. The
    %   number of sound sources that should be segregated must be specified
    %   upon initialization. Each mask is associated with a corresponding
    %   estimate of the source position, given as Gaussian distributions.
    %   The segmentation stage can be initialized with additional prior
    %   information, if estimated of the positions of certain sound sources
    %   are available.
    %
    % AUTHORS:
    %   Christopher Schymura (christopher.schymura@rub.de)
    %   Cognitive Signal Processing Group
    %   Ruhr-Universitaet Bochum
    %   Universitaetsstr. 150, 44801 Bochum

    properties (SetAccess = private)
        name;                       % Name of the KS instance
        nChannels;                  % Number of gammatone channels
        winSize;                    % Window size in [s]
        hopSize;                    % Hop size in [s]
        fLow;                       % Lowest center frequency of the 
                                    % gammatone filterbank in [Hz].
        fHigh;                      % Highest center frequency of the
                                    % gammatone filterbank in [Hz].
        bTrain = false;             % Flag, indicating if the KS is in 
                                    % training mode
        bVerbose = false;           % Display processing information?
        dataPath = ...              % Path for storing trained models
            fullfile(xml.dbTmp, 'learned_models', 'SegmentationKS');                                    
    end

    methods (Access = public)
        function obj = SegmentationKS(name, varargin)
            % SEGMENTATIONKS This is the class constructor. This KS can
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
            %   bTrain - Flag for setting the KS into training mode
            %            (default = false).
                                    
            % Set AFE requests
            requests = {'itd', 'ild'};
            obj = obj@AuditoryFrontEndDepKS(requests);
            
            % Check inputs
            p = inputParser();
            defaultNumChannels = 32;
            defaultWindowSize = 0.02;
            defaultHopSize = 0.01;
            defaultFLow = 80;
            defaultFHigh = 5000;
            defaultBVerbose = false;
            defaultBTrain = false;
            
            p.addRequired('name', @ischar);
            p.addOptional('bTrain', defaultBTrain, @islogical);
            p.addParameter('NumChannels', defaultNumChannels, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'integer', 'scalar', 'nonnegative'}));
            p.addParameter('WindowSize', defaultWindowSize, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'real', 'scalar', 'nonnegative'}));
            p.addParameter('HopSize', defaultHopSize, ...
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
            
            % Instantiate KS
            obj.name = p.Results.name;
            obj.nChannels = p.Results.NumChannels;
            obj.winSize = p.Results.WindowSize;
            obj.hopSize = p.Results.HopSize;
            obj.fLow = p.Results.FLow;
            obj.fHigh = p.Results.FHigh;
            obj.bVerbose = p.Results.Verbosity;
            obj.bTrain = p.Results.bTrain;
        end

        function delete(obj)

        end

        function [bExecute, bWait] = canExecute(obj)

        end

        function execute(obj)
           
        end

        function obj = generateTrainingData(obj, sceneDescription)
            % GENERATETRAININGDATA This function generates a dataset
            %   containing interaural time- and level-differences for a set
            %   of specified source positions. The source positions used
            %   for training are arranged on a circle around the listeners'
            %   head, ranging from -90° to 90° with 1° angular resolution.
            %   For each source position, binaural signals will be
            %   generated using broadband noise in anechoic conditions. The
            %   generated signals have a fixed length of one second per 
            %   source position.
            %
            % REQUIRED INPUTS:
            %   sceneDescription - Scene description file in XML-format,
            %       that will be used by the Binaural Simulator to create
            %       binaural signals.
            
            % Check inputs
            p = inputParser();
            
            p.addRequired('sceneDescription', @(x) exist(x, 'file'));
            p.parse(sceneDescription);
            
            % Check if KS is set to training mode
            if ~obj.bTrain
                error(['LocationKS has to be initiated in training ', ...
                    'mode to allow for this functionality.']);
            end
            
            % Check if folder for storing training data exists
            if ~exist(fullfile(obj.dataPath, obj.name), 'dir')
                mkdir(fullfile(obj.dataPath, obj.name))
            end
            
            % Initialize Binaural Simulator
            sim = simulator.SimulatorConvexRoom(sceneDescription);
            sim.Verbose = false;
            
            % Initialize source as white noise target
            set(sim, 'Sources', {simulator.source.Point()});
            set(sim.Sources{1}, 'AudioBuffer', simulator.buffer.Noise());
            
            % Set simulation length to 1 second
            set(sim, 'LengthOfSimulation', 1);
            
            % Set look direction of the head to 0 degrees
            sim.rotateHead(0, 'absolute');
            
            % Start simulation
            set(sim, 'Init', true);
            
            % Initialize auditory front-end and get AFE parameters
            afeParameters = obj.getAfeParameters();
            dataObj = dataObject([], sim.SampleRate, ...
                sim.LengthOfSimulation, 2);
            managerObj = manager(dataObj, obj.requests, afeParameters);
            
            % Generate vector of azimuth positions
            % TODO: This can be extended to be set by the user in a future
            % version.
            nPositions = 181;
            angles = linspace(-90, 90, nPositions);

            for k = 1 : nPositions
                if obj.bVerbose
                    disp(['Generating training features (', ...
                        num2str(k), '/', num2str(nPositions), ') ...']);
                end
                
                % Get current angle
                angle = angles(k);
                
                % Set source position
                set(sim.Sources{1}, 'Position', ...
                    [cosd(angle); sind(angle); 0]);
                
                % Re-initialize Binaural Simulator and AFE
                set(sim, 'ReInit', true);
                dataObj.clearData();
                managerObj.reset();
                
                % Get audio signal
                earSignals = sim.getSignal(sim.LengthOfSimulation);
                
                % Process ear signals
                managerObj.processSignal(earSignals);
                
                % Get binaural features
                itds = dataObj.itd{1}.Data(:);
                ilds = dataObj.ild{1}.Data(:);
                
                % Assemble filename for current set of features
                filename = [obj.name, '_', num2str(angle), 'deg.mat'];
                
                % Save features and meta-data to file
                save(fullfile(obj.dataPath, obj.name, filename), ...
                    'itds', 'ilds', 'angle', 'afeParameters', '-v7.3');
            end
        end

        function obj = removeTrainingData(obj)
          
        end

        function obj = train(obj)
          
        end
    end
    
    methods (Access = private)
        function afeParameters = getAfeParameters(obj)
            % GETAFEPARAMETERS This function returns a parameter set that
            %   can be handled by the Auditory Front-End. The parameter set
            %   is created using the processing options the KS is
            %   instantiated with.
            %
            % OUTPUTS:
            %   afeParameters - AFE parameter structure
            
            % Set parameters for the gammatone filterbank processor
            fb_type = 'gammatone';
            fb_lowFreqHz = obj.fLow;
            fb_highFreqHz = obj.fHigh;
            fb_nChannels = obj.nChannels;
            
            % Set parameters for the cross-correlation processor
            cc_wSizeSec = obj.winSize;
            cc_hSizeSec = obj.hopSize;
            cc_wname = 'hann';
            
            % Set parameters for the ILD processor
            ild_wSizeSec = obj.winSize;
            ild_hSizeSec = obj.hopSize;
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
        end
    end
end