classdef SoundSource < handle
    %SOUNDSOURCE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = private)
        signal                  % Time-domain signal representation of the
                                % sound source
    end
    
    properties (Access = private, Constant)
        SPEED_OF_SOUND = 343;   % Speed of sound in m/s
    end
    
    properties (GetAccess = public, SetAccess = private)
        name                    % Source name
        fs                      % Sampling frequency in Hz
        numSamples              % Signal length in samples
        position                % Source position with respect to the
                                % listener (x, y coordinates) in m
        distance                % Distance to listener in m
        azimuth                 % Horizontal angular position with respect
                                % to the listener in deg
    end
    
    methods (Access = public)
        function obj = SoundSource(name, audioFile, varargin)
            % SOUNDSOURCE Class constructor
            
            %% Error handling
            
            % Check number of input arguments
            if nargin ~= 4
                error('Incorrect number of input arguments.');
            end
            
            % Check if name variable is a valid string
            if ~isa(name, 'char')
                error('Specified name is not a valid string.');
            end
            
            % Check if audioFile is a valid file
            if ~isa(audioFile, 'char') || exist(audioFile, 'file') == 0
                error([audioFile, ' does not exist.']);
            end            
            
            % Check if coordinate system specification is correct
            if ~strcmp(varargin{1}, 'Cartesian') && ...
                    ~strcmp(varargin{1}, 'Polar')
                error('Invalid specification of coordinate system.');
            end
            
            % Position vector has te be either 1x2 or 2x1, so size has
            % to sum up to 3 and type has to be double
            if sum(size(varargin{2})) ~= 3 || ...
                    ~isa(varargin{2}, 'double')
                error('Position has to be a 2-dimensional vector.');
            end
            
            % Check if horizontal angle is properly defined
            if strcmp(varargin{1}, 'Polar')
                posPolar = varargin{2};
                if posPolar(2) < 0 || ...
                        posPolar(2) > 360
                    error('Invalid specification of angular position.');
                end
            end
            
            %% Parameter initialization
            
            % Assign name to sound source object
            obj.name = name;
            
            % Read and assign audio data
            [audioSignal, obj.fs] = wavread(audioFile);
            
            % Assign signal length
            obj.numSamples = length(audioSignal);
            
            % Normalize and assign time-domain signal
            obj.signal = audioSignal / max(audioSignal);
            
            % Compute and assign sound source position            
            if strcmp(varargin{1}, 'Cartesian')
                % Get cartesian coordinates
                posCart = varargin{2};
                
                % Assign to source position
                obj.position = posCart;
                
                % Compute distance and horizontal angle
                obj.distance = sqrt(posCart(1)^2 + posCart(2)^2);
                phi = atan2d(posCart(2), posCart(1));
                
                if phi < 0
                    phi = mod(phi + 360, 360);
                end
                
                obj.azimuth = phi;
            else
                % Assign distance and horizontal angle
                obj.distance = posPolar(1);
                obj.azimuth = posPolar(2);
                
                % Get polar coordinates
                r = posPolar(1);
                phi = posPolar(2) * pi / 180;
                
                % Transform polar coordinates into cartesian position
                posCart = zeros(1, 2);
                posCart(1) = r * cos(phi);
                posCart(2) = r * sin(phi);
                
                % Assign to source object
                obj.position = posCart;                
            end            
        end
        function processedSignal = getSignal(obj, referenceDistance)
            % GETSIGNAL Outputs time-domain signal of specified sound
            % source with the corresponding attenuation and time delay
            % regarding the distance of the source from the lsitener
            
            %% Error handling
            
            % Check number of input arguments
            if nargin ~= 2
                error('Incorrect number of input arguments.');
            end
            
            % Check if reference distance is of type double
            if ~isa(referenceDistance, 'numeric')
                error('Reference distance has to be of type double.');
            end
            
            %% Compute parameters
            
            % Compute propagation delay in samples
            timeDelay = ceil(obj.distance / obj.SPEED_OF_SOUND * obj.fs);
            
            % Compute signal attenuation according to distance
            attenuation = referenceDistance / obj.distance;
            
            % Output processed signal
            %processedSignal = [zeros(timeDelay, 1); ...
                %attenuation * obj.signal];
            processedSignal = obj.signal;
        end
    end
    
end

