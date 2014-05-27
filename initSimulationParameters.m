function sp = initSimulationParameters(preset)

%% Error handling

if ~isa(preset, 'char')
    error('Preset specification has to be of type char.');
end

%% Define simulation parameter struct

switch(lower(preset))
    
    case 'default'        
        % Input signal
        sp.fsHz       = 44.1E3;
        sp.bNormRMS   = false;
        
        % Auditory periphery
        sp.nErbs      = 1;          % ERB spacing of gammatone filters
        sp.nChannels  = 32;         % Number of GFB channels
        sp.mEarF      = true;       % Use middle ear filter
        sp.fLowHz     = 80;         % Lowest center frequency in Hertz
        sp.fHighHz    = 8E3;        % Highest center frequency in Hertz
        sp.bAlign     = false;      % Time-align auditory channels
        sp.ihcMethod  = 'halfwave';
        
        % Binaural cross-correlation processor
        sp.maxDelaySec = 1.0E-3;
        
        % Framing parameters
        sp.blockSize  = 100E-3;     % Block size on layer 1a
        sp.winSizeSec = 20E-3;      % Window size in seconds
        sp.hopSizeSec = 10E-3;      % Window step size in seconds
        sp.winType    = 'hann';     % Window type
        
        % Angles and head rotation
        sp.angularResolution = 5;
        sp.headRotateAngle = 30;
        
    case 'fa2014'        
        % Input signal
        sp.fsHz       = 16E3;
        sp.bNormRMS   = false;
        
        % Auditory periphery
        sp.nErbs      = 1;          % ERB spacing of gammatone filters
        sp.nChannels  = 32;         % Number of GFB channels
        sp.mEarF      = true;       % Use middle ear filter
        sp.fLowHz     = 80;         % Lowest center frequency in Hertz
        sp.fHighHz    = 8E3;        % Highest center frequency in Hertz
        sp.bAlign     = false;      % Time-align auditory channels
        sp.ihcMethod  = 'halfwave';
        
        % Binaural cross-correlation processor
        sp.maxDelaySec = 1.0E-3;
        
        % Framing parameters
        sp.blockSize  = 200E-3;     % 200 msec = 20 frames
        sp.winSizeSec = 20E-3;      % Window size in seconds
        sp.hopSizeSec = 10E-3;      % Window step size in seconds
        sp.winType    = 'hann';     % Window type
        
        % Angles and head rotation
        sp.angularResolution = 5;
        sp.headRotateAngle = 10;
        
    otherwise
        error('Preset is not supported');
end

