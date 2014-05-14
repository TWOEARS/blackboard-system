classdef Scene < handle
    %SCENE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (GetAccess = public, SetAccess = private)
        duration                % Scene duration in s
        fs                      % Sampling frequency in Hz
        numberOfSources         % Number of sound sources in the scene
        head                    % Dummy head parameters
        timeSteps               % Number of timesteps
        numSamples              % Total number of samples in time-domain
        frameLength             % Frame length in samples
        frameShift              % Frame shift in samples
        
    end
    
    properties (Access = private)
        signals = {};           % Cell array containing time-domain
                                % signals of sound sources
        angles = {};            % Cell array containing azimuths
                                % corresponding to the sound sources
    end
    
    methods (Access = public)
        function obj = Scene(duration, fs, frameLength, frameShift, ...
                head, varargin)
            % SCENE Class constructor
            
            %% Error handling
            
            % Check number of input arguments
            if nargin < 6
                error('Incorrect number of input arguments.');
            end
            
            % Check type of duration
            if ~isa(duration, 'double')
                error('Invalid specification of scene duration.');
            end
            
            % Check type of sampling frequency
            if ~isa(fs, 'double')
                error('Invalid specification of sampling frequency.');
            end
            
            % Check type of frame length
            if ~isa(frameLength, 'double')
                error('Invalid specification of frame length.');
            end
            
            % Check type of frame length
            if ~isa(frameShift, 'double')
                error('Invalid specification of frame shift.');
            end
            
            % Check type of head
            if ~isa(head, 'handle')
                error('Invalid head object.');
            end
            
            % Check types of sound sources
            for k = 1 : length(varargin)
                if ~isa(varargin{k}, 'handle')
                    error('Invalid sound source object(s).');
                end
            end
            
            %% Parameter initialization
            
            % Assign scene duration
            obj.duration = duration;
            
            % Assign sampling frequency
            obj.fs = fs;
            
            % Assign frame length
            obj.frameLength = frameLength;
            
            % Assign frame shift
            obj.frameShift = frameShift;
            
            % Assign number of samples
            obj.numSamples = duration * fs;
            
            % Compute and assign number of time steps
            overlap = frameLength - frameShift;
            obj.timeSteps = ceil((obj.numSamples - overlap) / ...
                (frameLength - overlap));
            
            % Assign head specifications
            obj.head = head;
            
            % Assign number of sources
            obj.numberOfSources = length(varargin);
            
            % Compute and assign source signals
            for k = 1 : length(varargin)
                tempSignal = varargin{k}.getSignal(obj.head.distance);
                
                % Match sampling frequency
                if varargin{1}.fs ~= obj.fs
                    tempSignal = resample(tempSignal, ...
                        obj.fs, varargin{k}.fs);
                end
                
                % Match signal length with scene duration
                if length(tempSignal) < obj.numSamples
                    tempSignal = [tempSignal; zeros(obj.numSamples - ...
                        length(tempSignal), 1)];
                else
                    tempSignal = tempSignal(1 : obj.numSamples);
                end
                
                % Store preprocessed source signal
                obj.signals{k} = tempSignal;
                
                % Store azimuth of k-th sound source
                obj.angles{k} = varargin{k}.azimuth;
            end
        end
        function frame = getFrame(obj, timeStep)
            % GETFRAME Returns processed signals (left/right) for the
            % specified timestep
            
            %% Error handling
            
            % Check number of input arguments
            if nargin ~= 2
                error('Incorrect number of input arguments.');
            end
            
            % Check correct timestep specification
            if ~isa(timeStep, 'double') || (timeStep <= 0 && ...
                    timeStep > obj.timeSteps)
                error('Invalid time step.');
            end
            
            %% Signal processing
            
            % Compute start and end indices
            startIndex = (timeStep - 1) * obj.frameShift + 1;
            endIndex = startIndex + obj.frameLength - 1;
            
            % Pre-allocate output frames
            convLength = ceil(obj.head.numSamples);
            rSignal = zeros(obj.frameLength + convLength - 1, 1);
            lSignal = zeros(obj.frameLength + convLength - 1, 1);
            
            % Process signal frames
            for k = 1 : obj.numberOfSources
                % Extract signal frame from sound source
                signalFrame = obj.signals{k};
                                
                if endIndex <= obj.numSamples
                    signalFrame = signalFrame(startIndex : endIndex);
                else
                    signalFrame = signalFrame(startIndex : obj.numSamples);
                    signalFrame = [signalFrame; zeros(endIndex - ...
                        obj.numSamples, 1)];
                end
                
                % Compute relative azimuth to source
                if obj.angles{k} >= obj.head.lookDirection
                    relativeAzimuth = obj.angles{k} - obj.head.lookDirection;
                else
                    relativeAzimuth = 360 - (obj.head.lookDirection - ...
                        obj.angles{k});
                end
                
                % Get hrirs
                hrirs = obj.head.getHrirs(relativeAzimuth);
                
                % Apply convolution
                rSignal = rSignal + fastconv(signalFrame, hrirs(:, 2));
                lSignal = lSignal + fastconv(signalFrame, hrirs(:, 1));
            end
            
            % Return processed signals
            frame = [lSignal rSignal];
        end
        function turnHead(obj, angularInc)
            %% TURNHEAD Updates look direction
            
            %% Error handling
            
            % Check number of input arguments
            if nargin ~= 2
                error('Incorrect number of input arguments.');
            end
            
            % Check if angle is correctly specified
%             if ~isa(control, 'double')
%                 error('Invalid angle specification.');
%             end
%            
%             % Check if control parameter is in correct range
%             if control < -1 || control > 1
%                 error('Head control parameter out of range.');
%             end
%             
%             %% Update look direction
%             
%             % Compute time increment per frame
%             timeInc = obj.frameShift / obj.fs;
%             
%             % Compute angular increment
%             angularInc = obj.head.MAX_TURN_SPEED * timeInc * control;
            
            % Add angular increment to look direction
            obj.head.lookDirection = mod(obj.head.lookDirection + ...
                angularInc, 360);            
        end
    end
    
end

