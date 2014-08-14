classdef SimulationWrapper < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        xmlFile             % XML file containing the scenario description
        simulator           % Instance of SSR SimulatorConvexRoom class
        targetSignal = [];  % Target signal
        targetAzimuth       % Azimuth of target signal in degrees
        maskerSignal = [];  % Masker signal
        maskerAzimuth       % Azimuth of masker signal in degrees
        noiseSignal = [];   % Noise signal
    end
    
    methods (Static)
        function audioData = readAudioFile(obj, filename)
            %% READAUDIOFILE
            %
            % TODO: Add proper documentation
            
            % TODO: Error handling
            
            % Read the audio file
            [signal, fsHz] = audioread(filename);
            
            % Upsample if necessary
            if fsHz ~= obj.simulator.SampleRate
                signal = resample(signal, ...
                    obj.simulator.SampleRate, fsHz);
            end
            
            % Normalize and return signal
            if isvector(signal)
                % In case of single channel signals
                audioData = signal ./ max(signal(:));
            else
                % If signal is stereo normalize all channels seperately
                numChannels = size(signal, 2);
                
                for k = 1 : numChannels
                    signal(:, k) = signal(:, k) ./ max(signal(:, k));
                end
                
                % Assign to output
                audioData = signal;
            end
        end
        
        function outputSignal = renderSignal(obj, signalType)
            %% RENDERSCENE
            %
            % TODO: Add proper documentation
            %
            % signalType: 'target', 'masker', 'noise'
            
            % TODO: Error handling
            
            % Re-Initialize simulation
            obj.simulator.set('ReInit', true);

            % Get length of the target signal
            targetLength = length(obj.targetSignal);
            
            switch signalType
                case 'target'
                    % Set target azimuth in simulator
                    obj.simulator.Sources(1).set('Azimuth', ...
                        obj.targetAzimuth);
                    
                    % Add target signal to simulator
                    obj.simulator.Sources(1).setData(obj.targetSignal);
                    
                    % Leave masker signal empty in this case
                    obj.simulator.Sources(2).setData(zeros(targetLength, 1));
                    
                    % Leave noise signal also empty (matrix with zeros)
                    obj.simulator.Sources(3).setData(zeros(targetLength, 2));
                case 'masker'
                    % Set masker azimuth in simulator
                    obj.simulator.Sources(2).set('Azimuth', ...
                        obj.maskerAzimuth);
                    
                    % Leave target signal empty in this case
                    obj.simulator.Sources(1).setData(zeros(targetLength, 1));
                    
                    % Add masker signal to simulator
                    obj.simulator.Sources(2).setData(obj.maskerSignal);
                    
                    % Leave noise signal also empty (matrix with zeros)
                    obj.simulator.Sources(3).setData(zeros(targetLength, 2));
                case 'noise'
                    % Leave target signal empty in this case
                    obj.simulator.Sources(1).setData(zeros(targetLength, 1));
                    
                    % Leave masker signal empty in this case
                    obj.simulator.Sources(2).setData(zeros(targetLength, 1));
                    
                    % Add noise signal to simulator
                    obj.simulator.Sources(3).setData(obj.noiseSignal);
                otherwise
                    error(['Signal type ', signalType, ' is not specified.']);
            end

            % Start the rendering process
            outputSignal = obj.simulator.getSignal(targetLength / ...
                obj.simulator.SampleRate); 
            
            % Normalize
            outputSignal = outputSignal / max(abs(outputSignal(:)));
        end
    end
    
    methods (Access = public)
        function obj = SimulationWrapper(xmlFile)
            %% SIMULATIONWRAPPER - Class constructor
            % Initialization of the simulation environment according to the
            % specifications in the XML file that is associated with the
            % corresponding class instance.
            
            % Check input
            if nargin ~= 1
                error('Wrong number of input arguments.');
            end
            
            % Import XML and simulation functionalities
            import xml.*
            import simulator.*
            
            % Create simnulator object
            obj.simulator = SimulatorConvexRoom();
            
            % Load scenario description from XML file
            obj.simulator.loadConfig(xmlFile);
            
            % Initialize simulation
            obj.simulator.set('Init', true);
        end
        
        function addTargetSignal(obj, targetSignalFile, targetAzimuth)
            %% ADDTARGETSIGNAL
            %
            % TODO: Add proper documentation
            
            % TODO: Add error handling
            
            % Add signal to class properties
            obj.targetSignal = obj.readAudioFile(obj, targetSignalFile);
            
            % Add azimuth to class properties
            obj.targetAzimuth = targetAzimuth;
        end
        
        function addMaskerSignal(obj, maskerSignalFile, maskerAzimuth)
            %% ADDTARGETSIGNAL
            %
            % TODO: Add proper documentation
            
            % TODO: Add error handling
            
            % Add signal to class properties
            obj.maskerSignal = obj.readAudioFile(obj, maskerSignalFile);
            
            % Add azimuth to class properties
            obj.maskerAzimuth = maskerAzimuth;
        end
        
        function addNoiseSignal(obj, noiseSignalFile)
            %% ADDTARGETSIGNAL
            %
            % TODO: Add proper documentation
            
            % TODO: Add error handling
            
            % Check if signal is stereo etc.
            
            % Add signal to class properties
            obj.noiseSignal = obj.readAudioFile(obj, noiseSignalFile);
        end
        
        function changeTargetAzimuth(obj, targetAzimuth)
            %% CHANGETARGETAZIMUTH
            %
            % TODO: Add proper documentation
            
            % TODO: Add error handling
            
            % Change azimuth in class properties
            obj.targetAzimuth = targetAzimuth;
        end
        
        function changeMaskerAzimuth(obj, maskerAzimuth)
            %% CHANGEMASKERAZIMUTH
            %
            % TODO: Add proper documentation
            
            % TODO: Add error handling
            
            % Change azimuth in class properties
            obj.maskerAzimuth = maskerAzimuth;
        end
        
        function outputSignal = renderSignals(obj, targetMaskerSNR, ...
                targetdiffuseSNR)
            %% RENDERSIGNALS - Rendering engine
            % Generates output signals according to the scenario
            % specification given in the scene XML file.
            %
            % TODO: Add parameter description
            
            % Check input
            if nargin ~= 3
                error('Wrong number of input arguments.');
            end
            
            % TODO: Sufficient error handling
            
            % Render individual signals
            outputSignal = obj.renderSignal(obj, 'target');
            
            if ~isempty(obj.maskerSignal)
                maskerOutput = obj.renderSignal(obj, 'masker');
                outputSignal = outputSignal + maskerOutput;
            end
            
            if ~isempty(obj.noiseSignal)
                noiseOutput = obj.renderSignal(obj, 'noise');
                outputSignal = outputSignal + noiseOutput;
            end
        end        
    end
end


