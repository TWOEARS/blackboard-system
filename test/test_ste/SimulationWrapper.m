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
        
        function outputSignal = renderSignals(obj, duration)
            %% RENDERSIGNALS - Rendering engine
            % Generates output signals according to the scenario
            % specification given in the scene XML file.
            
            % Check input
            if nargin ~= 2
                error('Wrong number of input arguments.');
            end
            
            if ~isa(duration, 'double') || numel(duration) ~= 1
                error(['The scene duration has to be specified as ', ...
                    'scalar value.']);
            end
            
            % Get output signal from SSR
            outputSignal = obj.simulator.getSignal(duration);
            
            % Normalize
            outputSignal = outputSignal / max(abs(outputSignal(:)));
        end
    end
end

