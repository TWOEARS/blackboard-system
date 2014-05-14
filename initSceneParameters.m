function [scene, sourcePos, out] = initSceneParameters(preset, sp)

%% Error handling

if ~isa(preset, 'char')
    error('Preset specification has to be of type char.');
end

if ~isa(sp, 'struct')
    error('Invalid simulation parameters.')
end

%% Define scene

switch(lower(preset))
    
    case 'stage1_random'        
        % Scene parameters
        duration = 10;               % Scene duration in seconds
        
        % Source signals and positions
        angles = 0:sp.angularResolution:359;
        s1Pos = angles(randi(length(angles)));
        s1 = SoundSource('Speech', 'speech.wav', 'Polar', [1, s1Pos]);

        % Define dummy head
        dummyHead = Head('QU_KEMAR_anechoic_1m.mat');
        
        % Create scene
        scene = Scene(duration, sp.fsHz, sp.winSizeSec * sp.fsHz, ...
            sp.hopSizeSec * sp.fsHz, dummyHead, s1);
        
        % Return source position
        sourcePos = s1Pos;
        
        % Allocate output signal
        out = zeros(scene.numSamples + sp.blockSize * sp.fsHz + ...
            dummyHead.numSamples - 1, 2);
        
        disp(['Source position: ', num2str(s1Pos)]);
        
    otherwise
        error('Preset is not supported');
end

