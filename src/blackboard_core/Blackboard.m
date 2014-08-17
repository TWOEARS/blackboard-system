classdef Blackboard < handle
    %Blackboard   A blackboard that solves the stage 1 task
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        KSs = {};                       % List of all KSs
        readyForNextBlock = true;       % 
        headOrientation = 0;            % Current head orientation
        signalBlocks = {};              % Layer 1a: Signals
        wp2signals = [];                % Layer 1a-2: _handles_ to wp2 signals
        locationHypotheses = [];        % Layer 3: Location hypotheses
        identityHypotheses = [];        % Layer 3: Identity hypotheses
        confusionHypotheses = [];       % Layer 4: Confusions
        perceivedLocations = [];        % Layer 5: Perceived source locations
        verbosity = 0;                  % Verbosity of 0 switches off screen output
    end
    
    events
        ReadyForNextBlock
        NewSignalBlock
        NewWp2Signal
        NewLocationHypothesis
        NewIdentityHypothesis
        NewConfusionHypothesis
        NewPerceivedLocation
    end
    
    methods
        %% Class constructor
        function obj = Blackboard(verbosity)
            if exist('verbosity', 'var')
                obj.verbosity = verbosity;
            end
        end
        
        %% Add KS to the blackboard system
        function obj = addKS(obj, ks)
            obj.KSs = [obj.KSs {ks}];
        end
                   
        %% Get number of KSs
        function n = numKSs(obj)
            n = length(obj.KSs);
        end

        %% Add general wp2 signal
        function obj = addWp2Signal( obj, regHash, regSignal )
            if isempty( obj.wp2signals )
                obj.wp2signals = containers.Map();
            end
            obj.wp2signals(regHash) = regSignal;
        end

        %% Add new signal block to layer 1a
        function n = addSignalBlock(obj, signalBlock)
            n_old = length(obj.signalBlocks);
            n = n_old + 1;
            obj.signalBlocks{n} = signalBlock;
        end
        
        %% Remove signal block from layer 1a
        function removeSignalBlock(obj)
            obj.signalBlocks = {};
        end
        
        %% Add new location hypothesis to layer 3a            
        function n = addLocationHypothesis(obj, location)
            obj.locationHypotheses = [obj.locationHypotheses location];
            n = length(obj.locationHypotheses);
        end
        
        %% Add new identity hypothesis to layer 3a            
        function n = addIdentityHypothesis( obj, identity )
            obj.identityHypotheses = [obj.identityHypotheses identity];
            n = length( obj.identityHypotheses );
        end
        
        %% Add confused frame to layer 3b
        function n = addConfusionHypothesis(obj, cf)
            obj.confusionHypotheses = [obj.confusionHypotheses cf];
            n = length(obj.confusionHypotheses);
        end
        
        %% Add new source ID hypothesis to layer 4
        function n = addPerceivedLocation(obj, pl)
            obj.perceivedLocations = [obj.perceivedLocations pl];
            n = length(obj.perceivedLocations);
        end
        
        %% Get number of signal blocks on the BB
        function n = getNumSignalBlocks(obj)
            n = length(obj.signalBlocks);
        end
        
        %% Get number of periphery signals on the BB
        function n = getNumPeripherySignals(obj)
            n = length(obj.peripherySignals);
        end
        
        %% Get number of acoustic cues on the BB
        function n = getNumAcousticCues(obj)
            n = length(obj.acousticCues);
        end
                
        %% Get number of location hypotheses on the BB
        function n = getNumLocationHypotheses(obj)
            n = length(obj.locationHypotheses);
        end
        
        %% Get number of confused frames on the BB
        function n = getNumConfusionHypotheses(obj)
            n = length(obj.confusionHypotheses);
        end
        
        %% Get number of perceived locations on the BB
        function n = getNumPerceivedLocations(obj)
            n = length(obj.perceivedLocations);
        end
        
        %% Ready for next frame
        function setReadyForNextBlock(obj, b)
            obj.readyForNextBlock = b;
            if b == true
                notify(obj, 'ReadyForNextBlock');
            end
        end
        
        %% Set absolute head orientation
        function setHeadOrientation(obj, angle)
            obj.headOrientation = angle;
        end
        
        %% Adjust relative to the current head orientation
        function adjustHeadOrientation(obj, angle)
            obj.headOrientation = mod(obj.headOrientation + angle, 360);
        end
        
        %% Reset head orientation to default look direction (0 degrees)
        function resetHeadOrientation(obj)
            obj.headOrientation = 0;
        end
    end
    
end
