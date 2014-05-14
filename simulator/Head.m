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
        angles                  % Angular representation deg/rad
    end
    
    methods (Access = public)
        function obj = Head(hrirFile, fs, initLookDirection)
            % HEAD Class constructor
            
            %% Error handling
            
            % Check number of input arguments
            if nargin < 1 || nargin > 3
                error('Incorrect number of input arguments.');
            end
            
            % Check if hrirFile is a valid file
            if ~isa(hrirFile, 'char') || exist(hrirFile, 'file') == 0
                error([hrirFile, ' does not exist.']);
            end
            
            % Check if initial look direction is correctly specified
            if nargin == 3
                if ~isa(initLookDirection, 'double') || ...
                        initLookDirection < 0 || initLookDirection > 360
                    error('Invalid specification of look direction.');
                end
            end
            
            %% Parameter initialization
            
            % Load MIRO file
            miroObject = load(hrirFile);
            objectName = fieldnames(miroObject); 
            
            % Assign MIRO object to hrirs parameter
            obj.hrirs = miroObject.(objectName{1});
            
            % Get angular representation
            obj.angles = obj.hrirs.angles;            
            
            % Assign sampling frequency
            obj.fs = obj.hrirs.fs;
            
            % Resample if necessary
            if fs ~= obj.hrirs.fs
                obj.hrirs.setResampling(fs);
            end
            
            % Assign reference distance
            obj.distance = obj.hrirs.sourceDistance;
            
            % Assign HRIR length
            obj.numSamples = obj.hrirs.taps;
            
            % Assign angular increment
            obj.increment = obj.hrirs.nIr / 360;
            
            % Assign initial look direction            
            if nargin == 3
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
                if strcmp(obj.angles, 'RAD')
                    azimuth = azimuth / 180 * pi;
                    elevation = pi / 2;
                else
                    elevation = 90;
                end
                
                hrirID = obj.hrirs.closestIr(azimuth, elevation);
                hrirPair = obj.hrirs.getIR(hrirID);    
                
                for k = 1 : 2
                    % Normalize
                    hrirPair(:, k) = hrirPair(:, k) / max(hrirPair(:, k));
                end
            else
                % If yes, ...
                
                % Compute parameters for linear interpolation
                lowerAzimuth = floor(azimuth);
                upperAzimuth = mod(lowerAzimuth + obj.increment, 360);
                
                if strcmp(obj.angles, 'RAD')
                    lowerAzimuth = lowerAzimuth / 180 * pi;
                    upperAzimuth = upperAzimuth / 180 * pi;
                    elevation = pi / 2;
                else
                    elevation = 90;
                end
                
                % Load corresponding HRIR's
                lowerID = obj.hrirs.closestIr(lowerAzimuth, elevation);
                upperID = obj.hrirs.closestIr(upperAzimuth, elevation);
                
                lowerHrirs = obj.hrirs.getIR(lowerID);
                upperHrirs = obj.hrirs.getIR(upperID);
                
                % Initialize output HRIR's
                hrirPair = zeros(obj.numSamples, 2);
                
                % Calculate interpolation coefficients:
                a = mod(azimuth, obj.increment) / obj.increment;
                b = 1 - a;
                
                % Perform linear interpolation                
                for k = 1 : 2
                    hrirPair(:, k) = a * lowerHrirs(:, k) + ...
                        b * upperHrirs(:, k);
                    
                    % Normalize
                    hrirPair(:, k) = hrirPair(:, k) / max(hrirPair(:, k));
                end
            end
        end
    end
    
end

