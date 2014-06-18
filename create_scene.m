function scene = create_scene(simParams, srcPos, srcWavFn, snr, envNoiseType)

% Define dummy head
dummyHead = Head('QU_KEMAR_anechoic_3m.mat', simParams.fsHz);

% Create target sound source
src = SoundSource('Speech', srcWavFn, 'Polar', [1, srcPos]);

if nargin <= 3
    envNoise = [];
else
    if isinf(snr)
        envNoise = [];
    else
        % Generate environmental noise with specified SNR
        switch(lower(envNoiseType))
            case 'bus'        
                noisefn = 'soundfiles/env_noise/bus01.wav';
            case 'busystreet'        
                noisefn = 'soundfiles/env_noise/busystreet01.wav';
            case 'office'        
                noisefn = 'soundfiles/env_noise/office01.wav';
            case 'park'        
                noisefn = 'soundfiles/env_noise/park01.wav';
            case 'supermarket'        
                noisefn = 'soundfiles/env_noise/supermarket01.wav';
            case 'tubestation'        
                noisefn = 'soundfiles/env_noise/tubestation01.wav';
            otherwise
                error('envNoiseType is not supported');
        end
        envNoise = Environment(noisefn, snr);
    end
end

% Create scene
scene = Scene(src.numSamples/src.fs, simParams.fsHz, simParams.blockSize * simParams.fsHz, ...
    simParams.blockSize * simParams.fsHz, dummyHead, envNoise, src);

