classdef Environment < handle
    % ENVIRONMENT - Class representing environmental (diffuse) noise
    %
    % Author:           Christopher Schymura
    % Email:            christopher.schymura@rub.de
    % Last revision:    27-May-2014
    %
    % ------------- BEGIN CODE --------------
    
    %% Class properties
    
    properties (SetAccess = private, GetAccess = public)
        fs                      % Sampling frequency in Hz
        numSamples              % Number of samples
        duration                % Duration of sound in seconds
        signals                 % Audio signals
        snr                     % SNR compared to spatial signals
    end
    
    %% Class methods
    
    methods (Access = public)
        function obj = Environment(filename, snr)
            %% ENVIRONMENT - Class constructor
            %
            %
            % ------------- BEGIN CODE --------------
            
            %% Error handling
            
            if nargin < 2
                error('Not enough input arguments.');
            end
            
            if ~exist(filename, 'file')
                error('Audio file not found.');
            end
            
            %% Parameter initialization
            
            % Load audio file
            [audioSignal, obj.fs] = audioread(filename);
            
            % Normalize both channels of signal to 1
            audioSignal(:, 1) = audioSignal(:, 1) / max(audioSignal(:, 1));
            audioSignal(:, 2) = audioSignal(:, 2) / max(audioSignal(:, 2));
            
            % Adapt signal gain to specified snr
            obj.snr = snr;
            
            % Assign audio signal to class
            obj.signals = audioSignal;
            
            % Assign number of samples
            obj.numSamples = length(audioSignal);
            
            % Assign duration of sound
            obj.duration = obj.numSamples / obj.fs;
            
        end
    end
end