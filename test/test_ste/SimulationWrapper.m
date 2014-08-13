classdef SimulationWrapper < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties %(Access = private)
        xmlFile             % XML file containing the scenario description
        simulator           % Instance of SSR SimulatorConvexRoom class        
    end
    
    methods
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
        
        function outputSignal = renderSignals(obj, targetFile, ...
                targetAzimuth, maskerFile, maskerAzimuth, ...
                diffuseNoiseFile, targetMaskerSNR, targetdiffuseSNR)
            %% RENDERSIGNALS - Rendering engine
            % Generates output signals according to the scenario
            % specification given in the scene XML file.
            %
            % TODO: Add parameter description
            
            % Check input
            if nargin ~= 8
                error('Wrong number of input arguments.');
            end
            
            % TODO: Sufficient error handling
            
            % Read target and masker signals
            if isempty(maskerFile)
                % Just compute the target signal if no masker was specified
                [targetSignal, fsHzTarget] = audioread(targetFile);
                
                % Upsample if necessary
                if fsHzTarget ~= obj.simulator.SampleRate
                    targetSignal = resample(targetSignal, ...
                        obj.simulator.SampleRate, fsHzTarget);
                end
                
                % Normalize
                targetSignal = targetSignal ./ max(targetSignal(:));
                
                % Add target signal to simulator
                obj.simulator.Sources(1).setData(targetSignal);
                
                % Leave masker signal empty in this case
                obj.simulator.Sources(2).setData(0);
                
                % Set target source location
                obj.simulator.Sources(1).set('Azimuth', targetAzimuth);
            else
                % Compute both signals otherwise
                [targetSignal, fsHzTarget] = audioread(targetFile);
                [maskerSignal, fsHzMasker] = audioread(maskerFile);
                
                % Upsample if necessary
                if fsHzTarget ~= obj.simulator.SampleRate
                    targetSignal = resample(targetSignal, ...
                        obj.simulator.SampleRate, fsHzTarget);
                end
                
                if fsHzMasker ~= obj.simulator.SampleRate
                    maskerSignal = resample(maskerSignal, ...
                        obj.simulator.SampleRate, fsHzMasker);
                end
                
                % Normalize
                targetSignal = targetSignal ./ max(targetSignal(:));
                maskerSignal = maskerSignal ./ max(maskerSignal(:));
                
                % Scale according to specified SNR between target and
                % masker
                targetSignal = std(maskerSignal) / std(targetSignal) * ...
                  (sqrt(10^(-targetMaskerSNR / 10))) * targetSignal;

                % Add target signal to simulator
                obj.simulator.Sources(1).setData(targetSignal);
                
                % Add masker signal to simulator
                obj.simulator.Sources(2).setData(maskerSignal);
                
                % Set source locations
                obj.simulator.Sources(1).set('Azimuth', targetAzimuth);
                obj.simulator.Sources(1).set('Azimuth', maskerAzimuth);
            end
            
            % Read diffuse noise signals
            if ~isempty(diffuseNoiseFile)
                % Read audio
                [noiseSignal, fsHzNoise] = audioread(diffuseNoiseFile);
                
                % Upsample if necessary
                if fsHzNoise ~= obj.simulator.SampleRate
                    noiseSignal = resample(noiseSignal, ...
                        obj.simulator.SampleRate, fsHzNoise);
                end
                
                % Normalize
                noiseSignal(:, 1) = noiseSignal(:, 1) ./ ...
                    max(noiseSignal(:, 1));
                noiseSignal(:, 2) = noiseSignal(:, 2) ./ ...
                    max(noiseSignal(:, 2));
                
                % Add diffuse noise signal to simulator
                obj.simulator.Sources(3).setData(noiseSignal);
            else
                % Leave diffuse noise signal empty if not specified
                dummy = zeros(length(obj.simulator.Sources(1).getData), 2);
                obj.simulator.Sources(3).setData(dummy);
            end
            
            % Render output signal
            while ~obj.simulator.Sources(1).isEmpty();
                obj.simulator.set('Refresh', true);
                obj.simulator.set('Process', true);
            end
            
            % Fetch output signal and cast to double
            outputSignal = double(obj.simulator.Sinks.getData());
            
            % Normalize
            outputSignal = outputSignal / max(abs(outputSignal(:)));
        end
    end
end

