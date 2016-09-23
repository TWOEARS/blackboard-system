classdef GenderRecognitionKS < AuditoryFrontEndDepKS
    % GENDERECOGNITIONKS Performs gender recognition (male/female).
    %
    % AUTHOR:
    %   Copyright (c) 2016      Christopher Schymura
    %                           Cognitive Signal Processing Group
    %                           Ruhr-Universitaet Bochum
    %                           Universitaetsstr. 150
    %                           44801 Bochum, Germany
    %                           E-Mail: christopher.schymura@rub.de
    %
    % LICENSE INFORMATION:
    %   This program is free software: you can redistribute it and/or
    %   modify it under the terms of the GNU General Public License as
    %   published by the Free Software Foundation, either version 3 of the
    %   License, or (at your option) any later version.
    %
    %   This material is distributed in the hope that it will be useful,
    %   but WITHOUT ANY WARRANTY; without even the implied warranty of
    %   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    %   GNU General Public License for more details.
    %
    %   You should have received a copy of the GNU General Public License
    %   along with this program. If not, see <http://www.gnu.org/licenses/>

    properties ( Access = private )
        basePath                % Path where extracted features and trained
                                % classifiers should be stored.
        pathToDataset           % Path to audio data for training and test.
    end
    
    properties ( Constant, Hidden )
        BLOCK_SIZE_SEC = 0.5;   % This KS works with a constant block size
                                % of 500ms.
    end
    
    methods ( Static, Hidden )
        function downloadGridCorpus()
            % DOWNLOADGRIDCORPUS Automatically downloads the endpointed 
            %   audio files of the GRID audiovisual sentence corpus from
            %   http://spandh.dcs.shef.ac.uk/gridcorpus/.
            
            % Check if folder for storing the GRID corpus exists and create
            % one if not.
            pathToGridCorpus = fullfile( db.path(), 'sound_databases', ...
                'grid_corpus' );
            
            if ~exist( pathToGridCorpus, 'dir' )
                mkdir( pathToGridCorpus );
            end
            
            % Number of speakers in GRID corpus is fixed to 34.
            NUM_SPEAKERS = 34;
            
            for speakerIdx = 1 : NUM_SPEAKERS
                % Check if files for current speaker have been downloaded.
                if ~exist( fullfile(pathToGridCorpus, ...
                        ['s', num2str(speakerIdx)]), 'dir' )
                    
                    disp(['GridCorpus::Downloading files for speaker ', ...
                        num2str(speakerIdx), ' ...']);
                    
                    % Assemble download URL for current speaker.
                    url = ['http://spandh.dcs.shef.ac.uk/gridcorpus/s', ...
                        num2str(speakerIdx), '/audio/s', num2str(speakerIdx), '.tar'];
                    
                    % Download and unpack audio files for current speaker.
                    untar( url, pathToGridCorpus );
                    
                    % Get path to audio files and perform sampling rate
                    % conversion.
                    pathToSpeakerFiles = fullfile(pathToGridCorpus, ...
                        ['s', num2str(speakerIdx)]);                    
                    fileList = getFiles( pathToSpeakerFiles, 'wav' );
                    
                    for file = fileList
                        info = audioinfo( fullfile(pathToSpeakerFiles, file{:}) );
                        
                        % Resample if necessary
                        if info.SampleRate ~= 44100
                            disp(['GridCorpus::Processing file ', file{:}, ...
                                ' for speaker ', num2str(speakerIdx), ' ...']);
                            
                            [signal, fs] = audioread( fullfile(pathToSpeakerFiles, file{:}) );
                            signal = resample( signal, 44100, fs );
                            
                            % Get number of replicates.
                            numReplicates = ceil( 44100 / length(signal) );
                            
                            % Replicate signal and truncate to desired
                            % length of 1s.
                            signal = repmat( signal(:), numReplicates, 1 );
                            signal = signal( 1 : 44100 );
                            
                            audiowrite( fullfile(pathToSpeakerFiles, file{:}), ...
                                signal, 44100 );
                        end
                    end
                end
            end
        end
        
        function replicatedSignal = replicateSignal( signal, ...
                signalLength, samplingRate )
            %REPLICATESIGNAL Summary of this function goes here
            %   Detailed explanation goes here
            
            % Get desired number of samples
            numSamples = ceil( signalLength * samplingRate );
            
            % Get number of replicates
            numReplicates = ceil( numSamples / length(signal) );
            
            % Replicate signal and truncate to desired length
            replicatedSignal = repmat( signal(:), numReplicates, 1 );
            replicatedSignal = replicatedSignal( 1 : numSamples );            
        end
    end    

    methods ( Access = public )
        function obj = GenderRecognitionKS()
            % GENDERECOGNITIONKS Method for class instantiation.
            %   Automaticlly handles classifier training if trained models
            %   are not available at instantiation. This KS is using a
            %   fixed set of parameters for feature extraction and
            %   classification, which cannot be changed by the user.
            
            % Generate AFE parameter structure. All parameters are fixed
            % and cannot be changed by the user.
            afeParameters = genParStruct( ...
                'pp_bNormalizeRMS', true, ...
                'ihc_method', 'halfwave', ...
                'fb_type', 'gammatone', ...
                'fb_lowFreqHz', 50, ...
                'fb_highFreqHz', 5000, ...
                'fb_nChannels', 32, ...
                'rm_wSizeSec', 0.02, ...
                'rm_hSizeSec', 0.01, ...
                'rm_wname', 'hann', ...
                'p_pitchRangeHz', [50, 600] );

            % Set AFE requests and instantiate AFE.
            requests{1}.name = 'ratemap';
            requests{1}.params = afeParameters;
            requests{2}.name = 'pitch';
            requests{2}.params = afeParameters;
            requests{3}.name = 'spectral_features';
            requests{3}.params = afeParameters;
            obj = obj@AuditoryFrontEndDepKS( requests );
            
            % Get path to stored features and models. If such a directory
            % does not exist, it will be created.
            obj.basePath = fullfile( db.tmp(), 'GenderRecognitionKS' );
            
            if ~exist( obj.basePath, 'dir' )
                mkdir( obj.basePath );
            end
            
            % Get path where audio files rendered are stored.
            obj.pathToDataset = fullfile( obj.basePath, 'data' );
            
            if ~exist( obj.pathToDataset, 'dir' )
                mkdir( obj.pathToDataset );
            end            
            
            obj.downloadGridCorpus();
            obj.generateDataset();
        end

        function [bExecute, bWait] = canExecute( obj )
            bExecute = obj.hasEnoughNewSignal( obj.BLOCK_SIZE_SEC );
            bWait = false;
        end

        function execute( obj )
            % Get features for current signal block.
            ratemap = obj.getNextSignalBlock( 1, ...
                obj.BLOCK_SIZE_SEC, obj.BLOCK_SIZE_SEC, false );
            pitch = obj.getNextSignalBlock( 2, ...
                obj.BLOCK_SIZE_SEC, obj.BLOCK_SIZE_SEC, false );
            spectralFeatures = obj.getNextSignalBlock( 3, ...
                obj.BLOCK_SIZE_SEC, obj.BLOCK_SIZE_SEC, false );            
        end
    end
    
    methods ( Access = private )
        function generateDataset( obj )
            % GENERATEDATASET
            
            pathToGridCorpus = fullfile( db.path(), 'sound_databases', ...
                'grid_corpus' );
            
            % Specify speakers for training and test sets.
            femaleSpeakers = {'s4', 's7', 's11', 's15', 's16', 's18', 's20', ...
                's21', 's22', 's23', 's24', 's25', 's29', 's31', 's33', 's34'};
            maleSpeakers = {'s1', 's2', 's3', 's5', 's6', 's8', 's9', 's10', ...
                's12', 's13', 's14', 's17', 's19', 's26', 's27', 's28', 's30', 's32'};
            trainSet = {femaleSpeakers{1 : end - 2}, maleSpeakers{1 : end - 4}};
            testSet = {femaleSpeakers{end - 2 : end}, maleSpeakers{end - 2 : end}};
            
            % Initialize the binaural simulator and fix all simulation parameters that
            % will not change during data generation.
            sim = simulator.SimulatorConvexRoom();
            
            sim.set( ...
                'Renderer', @ssr_binaural, ...
                'SampleRate', 44100, ...
                'MaximumDelay', 0.05, ...
                'PreDelay', 0.0, ...
                'LengthOfSimulation', 1, ...    % Fixed to one second here.
                'Sources', {simulator.source.Point()}, ...
                'Sinks', simulator.AudioSink(2), ...
                'HRIRDataset', simulator.DirectionalIR('impulse_responses/qu_kemar_anechoic/QU_KEMAR_anechoic_3m.sofa'), ...
                'Verbose', false );
            
            sim.Sources{1}.set( ...
                'Name', 'Speech', ...
                'AudioBuffer', simulator.buffer.Ring, ...
                'Volume', 1, ...
                'Position', [cosd(0); sind(0); 1.75] );
            
            sim.Sinks.set( ...
                'Position', [0; 0; 1.75], ...   % Cartesian position of the dummy head
                'Name', 'DummyHead' );          % Identifier of the audio sink.
            
            for currentSet = {'train', 'test'}
                if strcmp( currentSet{:}, 'train' )
                    speakerIds = trainSet;
                else
                    speakerIds = testSet;
                end
                numSpeakers = length(speakerIds);
                
                for speaker = speakerIds
                    % Get gender of current speaker.
                    if any( strcmp(speaker{:}, femaleSpeakers) )
                        gender = 'female';
                    else
                        gender = 'male';
                    end
                    
                    % Check if folder for storing audio data exists.
                    pathToAudioFiles = fullfile( obj.pathToDataset, ...
                        currentSet{:}, gender );
                    
                    if ~exist( pathToAudioFiles, 'dir' )
                        mkdir( pathToAudioFiles );
                    end
                    
                    % Get all audio files for current speaker.
                    listOfAudioFiles = getFiles( fullfile( ...
                        pathToGridCorpus, speaker{:}), 'wav' );
                    
                    for file = listOfAudioFiles
                        [~, filename] = fileparts( file{:} );
                        processedFileName = ...
                            [speaker{:}, '_', filename, '_', gender, '.wav'];
                        pathToFile = fullfile(pathToAudioFiles, processedFileName);
                        
                        if ~exist( pathToFile, 'file' )
                            % Add audio file to simulator.
                            set( sim.Sources{1}.AudioBuffer, ...
                                'File', fullfile(pathToGridCorpus, speaker{:}, file{:}) );    
                            sim.init();
                        end
                    end
                end
            end
        end
    end
end