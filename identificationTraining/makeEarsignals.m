function signals = makeEarsignals( monoSound, head, angle, niState )

convLength = ceil( niState.simParams.fsHz / head.fs * head.numSamples);
signals = zeros(length(monoSound) + convLength - 1, 2);

% Get hrirs
hrirs = head.getHrirs(angle);

% Apply convolution
signals(:,1) = fastconv( monoSound, hrirs(:, 2) );
signals(:,2) = fastconv( monoSound, hrirs(:, 1) );

