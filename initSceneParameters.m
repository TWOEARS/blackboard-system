function [scene, sourcePos, out] = initSceneParameters(preset, sp, duration)

%% Error handling

if ~isa(preset, 'char')
    error('Preset specification has to be of type char.');
end

if ~isa(sp, 'struct')
    error('Invalid simulation parameters.')
end

%% Define scene

switch(lower(preset))
    
    case 'stage1_freefield'
        % Source signals and positions
        angles = 0:sp.angularResolution:359;
        s1Pos = angles(randi(length(angles)));
        %s1Pos = 90;
        s1 = SoundSource('Speech', 'speech.wav', 'Polar', [1, s1Pos]);
        
        % Define dummy head
        dummyHead = Head('HRIR_CIRC360.mat', sp.fsHz);
        
        % Create scene
        scene = Scene(duration, sp.fsHz, sp.blockSize * sp.fsHz, ...
            sp.blockSize * sp.fsHz, dummyHead, s1);
        
        % Return source position
        sourcePos = s1Pos;
        
        % Allocate output signal
        out = zeros(scene.numSamples + sp.blockSize * sp.fsHz + ...
            dummyHead.numSamples - 1, 2);
        
        disp(['Source position: ', num2str(s1Pos)]);
        
    case 'stage1_reverb'
        % Possible source positions
        sPos = [0, 30, 45, 90, 110, 135, 180, 225, 250, 270, 315, 330];
        
        % Get random source position
        s1Pos = sPos(randi(length(sPos)));
        
        % Get BRIR file
        filename = 'SBSBRIR.mat';
        
        s1 = SoundSource('Speech', 'speech.wav', 'Polar', [1, 0]);
        
        % Define dummy head
        dummyHead = Head(filename, sp.fsHz);
        
        % Create scene
        scene = Scene(duration, sp.fsHz, sp.blockSize * sp.fsHz, ...
            sp.blockSize * sp.fsHz, dummyHead, s1);
        
        % Return source position
        sourcePos = s1Pos;
        
        % Allocate output signal
        out = zeros(scene.numSamples + sp.blockSize * sp.fsHz + ...
            dummyHead.numSamples - 1, 2);
        
        disp(['Source position: ', num2str(s1Pos)]);
        
    otherwise
        error('Preset is not supported');
end

