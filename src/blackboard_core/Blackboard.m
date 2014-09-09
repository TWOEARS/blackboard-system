classdef Blackboard < handle
    %Blackboard   A blackboard that solves the stage 1 task
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        KSs = {};                       % List of all KSs
        headOrientation = 0;            % Current head orientation
        wp2signals = [];                % Layer 1a-2: _handles_ to  requested signals
        locationHypotheses = [];        % Layer 3: Location hypotheses
        confusionHypotheses = [];       % Layer 4: Confusions
        perceivedLocations = [];        % Layer 5: Perceived source locations
        data = [];                      % general data storage Map, with currentSoundTimeIdx as key
        verbosity = 0;                  % Verbosity of 0 switches off screen output
        currentSoundTimeIdx = 0;
    end
    
    events
        NextSoundUpdate
        NewWp2Signal
        NewLocationHypothesis
        NewIdentityHypothesis
        NewIdentityDecision
        NewConfusionHypothesis
        NewPerceivedLocation
    end
    
    methods
        %% Class constructor
        function obj = Blackboard(verbosity)
            if exist('verbosity', 'var')
                obj.verbosity = verbosity;
            end
            obj.data = containers.Map( 'KeyType', 'uint64', 'ValueType', 'any' );
        end
        
        %% Add KS to the blackboard system
        function obj = addKS(obj, ks)
            obj.KSs = [obj.KSs {ks}];
        end
                   
        %% Get number of KSs
        function n = numKSs(obj)
            n = length(obj.KSs);
        end
        
        %% Set currentSoundTimeIdx
        function obj = setSoundTimeIdx( obj, newSoundTimeIdx )
            if newSoundTimeIdx <= obj.currentSoundTimeIdx
                error( 'time is usually monotonically increasing.' );
            end
            obj.currentSoundTimeIdx = newSoundTimeIdx;
        end

        %% Add general wp2 signal
        function obj = addWp2Signal( obj, regHash, regSignal )
            if isempty( obj.wp2signals )
                obj.wp2signals = containers.Map();
            end
            obj.wp2signals(regHash) = regSignal;
        end

        %% Add new location hypothesis to layer 3a            
        function n = addLocationHypothesis(obj, location)
            obj.locationHypotheses = [obj.locationHypotheses location];
            n = length(obj.locationHypotheses);
        end
        
        %% Add new data to blackboard
        % append=true ->    save more than one date per timestep,
        %                   for example several identity hypotheses
        function n = addData( obj, dataLabel, data, append )
            if obj.data.isKey( obj.currentSoundTimeIdx ) 
                curData = obj.data(obj.currentSoundTimeIdx);
            else
                curData = [];
            end
            if append && isfield( curData, dataLabel )
                curData.(dataLabel) = [curData.(dataLabel), data];
            else
                curData.(dataLabel) = data;
            end
            obj.data(obj.currentSoundTimeIdx) = curData;
            n = obj.currentSoundTimeIdx;
        end
        
        %% get data from blackboard
        %   reqSndTimeIdxs:	optional. Array of time indexes requested.
        %                   if not given, all time indexes available are used
        function requestedData = getData( obj, dataLabel, reqSndTimeIdxs )
            if nargin < 3
                reqSndTimeIdxs = sort( cell2mat( keys( obj.data ) ) );
            end
            k = 1;
            requestedData = [];
            for sndTmIdx = reqSndTimeIdxs
                if ~isfield( obj.data(sndTmIdx), dataLabel ), continue; end;
                requestedData(k).sndTmIdx = sndTmIdx;
                dtmp = obj.data(sndTmIdx);
                requestedData(k).data = dtmp.(dataLabel);
                k = k + 1;
            end
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
        function setReadyForNextBlock(obj)
            notify(obj, 'NextSoundUpdate');
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
