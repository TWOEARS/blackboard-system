classdef Head < handle
    %HEAD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (GetAccess = public, SetAccess = public)
        fs                      % Sampling frequency in Hz
        lookDirection = 0;      % Look direction in the horizontal plane in
                                % degrees (0 ... 360)
        distance                % Reference distance of hrir's in m
        numSamples              % Length of HRIR's in samples
        increment               % Measured angular increment
    end
    
    properties (Access = public)
        MAX_TURN_SPEED = 30;    % Maximum turning speed in deg/s
    end
    
    properties (Access = private)
        hrirs                   % HRIR data structure
        servoSounds = {};       % Time domain signals of servo-sounds as
                                % 3D-Cell array
    end
    
    methods (Access = public)
        function obj = Head(hrirFile, initLookDirection)
            % HEAD Class constructor
            
            %% Error handling
            
            % Check number of input arguments
            if nargin < 1 || nargin > 2
                error('Incorrect number of input arguments.');
            end
            
            % Check if hrirFile is a valid file
            if ~isa(hrirFile, 'char') || exist(hrirFile, 'file') == 0
                error([hrirFile, ' does not exist.']);
            end
            
            % Check if initial look direction is correctly specified
            if nargin == 2
                if ~isa(initLookDirection, 'double') || ...
                        initLookDirection < 0 || initLookDirection > 360
                    error('Invalid specification of look direction.');
                end
            end
            
            %% Parameter initialization
            
            % Load HRIR file
            obj.hrirs = read_irs(hrirFile);
            
            % Assign sampling frequency
            obj.fs = obj.hrirs.fs;
            
            % Assign reference distance
            obj.distance = obj.hrirs.distance;
            
            % Assign HRIR length
            obj.numSamples = size(obj.hrirs.left, 1);
            
            % Assign angular increment
            obj.increment = size(obj.hrirs.left, 2) / 360;
            
            % Assign initial look direction            
            if nargin == 2
                obj.lookDirection = initLookDirection;
            end
        end
        function [hrirPair, azimuth] = getHrirs(obj, azimuth)
            % GETHRIRS Returns a pair of HRIR's (left/right) corresponding
            % to the specified horizontal sourceAzimuth
            
            %% Error handling
            
            % Check number of input arguments
            if nargin ~= 2
                error('Incorrect number of input arguments.');
            end
            
            % Azimuth error handling ...
            
            %% HRIR interpolation
            
            % Check if linear interpolation is necessary
            if mod(azimuth, obj.increment) == 0
                % If not, return measured HRIR's
                hrirPair = get_ir(obj.hrirs, azimuth);
            else
                % If yes, ...
                
                % Compute parameters for linear interpolation
                lowerAzimuth = floor(azimuth);
                upperAzimuth = mod(lowerAzimuth + obj.increment, 360);
                
                % Load corresponding HRIR's
                lowerHrirs = get_ir(obj.hrirs, lowerAzimuth);
                upperHrirs = get_ir(obj.hrirs, upperAzimuth);
                
                % Initialize output HRIR's
                hrirPair = zeros(obj.numSamples, 2);
                
                % Calculate interpolation coefficients:
                a = mod(azimuth, obj.increment) / obj.increment;
                b = 1 - a;
                
                % Perform linear interpolation                
                for k = 1 : 2
                    hrirPair(:, k) = a * lowerHrirs(:, k) + ...
                        b * upperHrirs(:, k);
                end
            end
        end
    end
    
end

