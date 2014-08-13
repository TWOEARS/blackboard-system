classdef SimulationWrapper < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
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
            
            % Check if XML file is valid
            try
                xml.dbValidate(xmlFile);
            catch
                error([xmlFile, ' is not a valid XML file.']);
            end
            
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
                obj.simulator.Sources(2).setData([]);
                
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
                
                % Add target signal to simulator
                sim.Sources(1).setData(targetSignal);
                
                % Add masker signal to simulator
                sim.Sources(2).setData(maskerSignal);
                
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
                sim.Sources(3).setData(noiseSignal);
            end
           
            % Get output signal from SSR
            outputSignal = obj.simulator.getSignal(duration);
            
            % Normalize
            outputSignal = outputSignal / max(abs(outputSignal(:)));
        end
    end
end

