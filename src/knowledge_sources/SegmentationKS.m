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
        bTrain = false;             % Flag, indicating if the KS is in
                                    % training mode
        bVerbose = false;           % Display processing information?
        dataPath = ...              % Path for storing trained models
            fullfile(xml.dbTmp, 'learned_models', 'SegmentationKS');
    end
    
    methods (Static)
        function fileList = getFiles(folder, extension)
            % GETFILES Returns a cell-array, containing a list of files 
            %   with a specified extension.
            %
            % REQUIRED INPUTS:
            %    folder - Path pointing to the folder that should be
            %       searched.
            %    extension - String, specifying the file extension that
            %       should be searched.
            %
            % OUTPUTS:
            %    fileList - Cell-array containing all files that were found
            %       in the folder. If no files with the specified extension
            %       were found, an empty cell-array is returned.
            
            % Check inputs
            p = inputParser();
            
            p.addRequired('folder', @isdir);
            p.addRequired('extension', @ischar);            
            parse(p, folder, extension);

            % Get all files in folder
            fileList = dir(fullfile(p.Results.folder, ...
                ['*.', p.Results.extension]));
            
            % Return cell-array of filenames
            fileList = {fileList(:).name};
        end
        
        % ------------ END OF CODE --------------
        %
        % Copyright (C) 2014 Christopher Schymura
        % All rights reserved.
        %
        % This software may be modified and distributed under the terms
        % of the BSD license.  See the LICENSE file for details.
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
            requests{1}.name = 'itd';
            requests{1}.params = afeParameters;
            requests{2}.name = 'ild';
            requests{2}.params = afeParameters;
            obj = obj@AuditoryFrontEndDepKS(requests);
            
            % Instantiate KS
            obj.name = p.Results.name;
            obj.bVerbose = p.Results.Verbosity;
            obj.bTrain = p.Results.bTrain;
        end

        function delete(obj)

        end

        function [bExecute, bWait] = canExecute(obj)

        end

        function execute(obj)
           
        end

        function generateTrainingData(obj, sceneDescription)
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
                error(['SegmentationKS has to be initiated in ', ...
                    'training mode to allow for this functionality.']);
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
            
            % Initialize auditory front-end
            dataObj = dataObject([], sim.SampleRate, ...
                sim.LengthOfSimulation, 2);
            managerObj = manager(dataObj);
            for idx = 1 : length(obj.requests)
                managerObj.addProcessor(obj.requests{idx}.name, ...
                    obj.requests{idx}.params);
            end
            
            %managerObj = manager(dataObj, obj.requests, obj.afeParameters);
            
            % Generate vector of azimuth positions
            % TODO: This can be extended to be set by the user in a future
            % version.
            nPositions = 181;
            angles = linspace(-90, 90, nPositions);

            for posIdx = 1 : nPositions
                if obj.bVerbose
                    disp(['Generating training features (', ...
                        num2str(posIdx), '/', num2str(nPositions), ') ...']);
                end
                
                % Get current angle
                angle = angles(posIdx);
                
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
                
                % Compute target vector from angles
                nFrames = size(itds, 1);
                targets = angle .* ones(nFrames, 1);
                
                % Get parameters
                parameters = obj.requests{1}.params;
                
                % Save features and meta-data to file
                save(fullfile(obj.dataPath, obj.name, filename), ...
                    'itds', 'ilds', 'targets', 'parameters', '-v7.3');
            end
        end

        function removeTrainingData(obj)
            % REMOVETRAININGDATA Training data that has already been
            %   generated for a specific instance of this knowledge source
            %   can be removed via this function.
            
            % Check if KS is set to training mode
            if ~obj.bTrain
                error(['SegmentationKS has to be initiated in ', ...
                    'training mode to allow for this functionality.']);
            end
            
            % Check if folder containing training data exists
            trainingFolder = fullfile(obj.dataPath, obj.name);
            if ~exist(trainingFolder, 'dir')
                error(['No folder containing training data can be ', ...
                    'found for SegmentaionKS of type ', obj.name, '.']);
            end
            
            % Get all mat-files from training folder
            filelist = obj.getFiles(trainingFolder, 'mat');            
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

        function obj = train(obj)
          
        end
    end
end