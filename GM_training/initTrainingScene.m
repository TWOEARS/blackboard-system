function [scene, sourcePos, out] = initTrainingScene(sceneDuration, azimuth, sp)

%% Error handling


if ~isa(sp, 'struct')
    error('Invalid simulation parameters.')
end

%% Define scene

% Source signals and positions
s1Pos = azimuth;
s1 = SoundSource('Speech', 'speech.wav', 'Polar', [1, s1Pos]);

% Define dummy head
dummyHead = Head('QU_KEMAR_anechoic_1m.mat');

% Create scene
scene = Scene(sceneDuration, sp.fsHz, sp.blockSize * sp.fsHz, ...
    sp.blockSize * sp.fsHz, dummyHead, s1);

% Return source position
sourcePos = s1Pos;

% Allocate output signal
out = zeros(scene.numSamples + sp.blockSize * sp.fsHz + ...
    dummyHead.numSamples - 1, 2);

disp(['Source position: ', num2str(s1Pos)]);
