classdef SimulationWrapper < handle
    % SIMULATIONWRAPPER This class can be used to generate a binaural
    % signal containing arbitrary target and masker sources with additional
    % ambient noise. It is possible to specify the SNR between the target
    % and the masker and between the target and the noise. The class is a
    % wrapper containing the simulation code provided by WP1.
    %
    % Authors :  Christopher Schymura
    %            Ruhr-Universität Bochum
    %            christopher.schymura@rub.de
    %
    % Last revision: 15/08/2014
    %
    % ------------- BEGIN CODE --------------
    
    properties (Access = private)
        simulator           % Instance of SSR SimulatorConvexRoom class
        targetSignal = [];  % Target signal
        targetAzimuth       % Azimuth of target signal in degrees
        maskerSignal = [];  % Masker signal
        maskerAzimuth       % Azimuth of masker signal in degrees
        noiseSignal = [];   % Noise signal
    end
    
    methods (Access = private)
        function audioData = readAudioFile(obj, filename)
            % READAUDIOFILE Helper-function that reads audio data from a
            % file, normalizes it and resamples to the sampling frequency
            % specified in the simulator.
            %
            % Inputs:
            %   filename - Valid filename of a .wav-file [string].
            %
            % Outputs:
            %   audioData - Normalized audio signals, represented as a NxC
            %   matrix, where N is the number of samples in the signal and
            %   C is the number of audio channels [matrix, double].
            %
            % Authors :  Christopher Schymura
            %            Ruhr-Universität Bochum
            %            christopher.schymura@rub.de
            %
            % Last revision: 15/08/2014
            %
            % ------------- BEGIN CODE --------------
            
            % Check input
            if nargin ~= 2
                error('Wrong number of input arguments.');
            end
            
            % Check output
            if nargout ~= 1
                error(['This function must be specified with an ', ...
                    'output argument.']);
            end
            
            % Check if input is a string
            if ~isa(filename, 'char')
                error([filename, ' is not a valid filename.']);
            end
            
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
            % RENDERSIGNAL Helper-function that individually computes the
            % target, masker or noise signal according to the specified
            % scene parameters.
            %
            % Inputs:
            %   signalType - Specification of the signal that should be 
            %   rendered [string]. Valid keywords are:
            %       - 'target': Renders the target signal
            %       - 'masker': Renders the masker signal
            %       - 'noise':  Renders the ambient noise
            %
            % Outputs:
            %   outputSignal - Rendered signal, represented as a NxC
            %   matrix, where N is the number of samples in the signal and
            %   C is the number of audio channels [matrix, double].
            %
            % Authors :  Christopher Schymura
            %            Ruhr-Universität Bochum
            %            christopher.schymura@rub.de
            %
            % Last revision: 15/08/2014
            %
            % ------------- BEGIN CODE --------------
            
            % Check input
            if nargin ~= 2
                error('Wrong number of input arguments.');
            end
            
            % Check output
            if nargout ~= 1
                error(['This function must be specified with an ', ...
                    'output argument.']);
            end
            
            % Check if input is a string
            if ~isa(signalType, 'char')
                error([signalType, ' is not a valid keyword.']);
            end
            
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
                    error(['Signal type ', signalType, ' is not ', ...
                        'specified. It has to be either ''target'', ', ...
                        '''masker'' or ''noise''.']);
            end

            % Start the rendering process
            outputSignal = obj.simulator.getSignal(targetLength / ...
                obj.simulator.SampleRate); 
            
            % Normalize and cast to double
            outputSignal = double(outputSignal / max(abs(outputSignal(:))));
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
            obj.targetSignal = readAudioFile(obj, targetSignalFile);
            
            % Add azimuth to class properties
            obj.targetAzimuth = targetAzimuth;
        end
        
        function addMaskerSignal(obj, maskerSignalFile, maskerAzimuth)
            %% ADDTARGETSIGNAL
            %
            % TODO: Add proper documentation
            
            % TODO: Add error handling
            
            % Add signal to class properties
            obj.maskerSignal = readAudioFile(obj, maskerSignalFile);
            
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
            obj.noiseSignal = readAudioFile(obj, noiseSignalFile);
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
                targetNoiseSNR)
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
            
            % Render target signal
            targetOutput = renderSignal(obj, 'target');
            
            % Assign target output to output signal
            outputSignal = targetOutput;
            
            % Render masker if specified
            if ~isempty(obj.maskerSignal)
                % Get masker signal
                maskerOutput = renderSignal(obj, 'masker');
                
                % Compute energies of target and masker signals
                energyTarget = sum(sum(abs(targetOutput).^2));
                energyMasker = sum(sum(abs(maskerOutput).^2));
                
                % Compute scaling factor for the masker signal
                maskerGain = sqrt((energyTarget / ...
                    (10^(targetMaskerSNR / 10))) / energyMasker);
                
                % Adjust the masker level to get required SNR
                maskerOutput = maskerGain * maskerOutput;
                
                % Generate output signal
                outputSignal = outputSignal + maskerOutput;
            end
            
            % Render noise if specified
            if ~isempty(obj.noiseSignal)
                % Get noise signal
                noiseOutput = renderSignal(obj, 'noise');
                
                % Compute noise energy
                energyTarget = sum(sum(abs(targetOutput).^2));
                energyNoise = sum(sum(abs(noiseOutput).^2));
                
                % Compute scaling factor for the noise signal
                noiseGain = sqrt((energyTarget / ...
                    (10^(targetNoiseSNR / 10))) / energyNoise);
                
                % Adjust the noise level to get required SNR
                noiseOutput = noiseGain * noiseOutput;
                
                % Generate output signal
                outputSignal = outputSignal + noiseOutput;
            end
        end        
    end
end


