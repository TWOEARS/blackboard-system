function wp2Features = wp2processSound( soundFile, niState )

%read audio
[stereoSound, fsHz] = audioread( soundFile );
fprintf( '.' );
[~,i] = max(std(stereoSound));
monoSound = stereoSound(:,i);
monoSound = [monoSound; zeros(2 * niState.samplesPerBlock,1)];
fprintf( '.' );
head = Head( 'HRIR_CIRC360.mat', niState.simParams.fsHz );
wp2Features = [];
for angle = niState.angles
    earSignals = makeEarsignals( monoSound, head, angle, niState );

    if size( earSignals, 1 ) < niState.samplesPerBlock + niState.hopSamples
        earSignals = [zeros( niState.samplesPerBlock + niState.hopSamples - size( earSignals,1 ), 2); earSignals];
    end
    [~,~,wp2features,~] = process_WP2( earSignals, niState.simParams.fsHz, niState.wp2states );
    fprintf( '.' );

    nFrames = size( wp2features.data, 2 );
    % split in blocks, for every block:
    for blockno = 1:ceil((nFrames - niState.hopsPerBlock + 1) / niState.hopsPerShift)+1 
        block = wp2features;
        blockstart = 1 + (blockno - 1) * niState.hopsPerShift;
        blockend = min( blockstart+niState.hopsPerBlock-1-1, nFrames );
        block.data = wp2features.data(:,blockstart:blockend,:);
        if size( block.data, 2 ) < niState.hopsPerBlock - 1
            block.data = wp2features.data(:,blockend-niState.hopsPerBlock+1+1:blockend,:);
        end

        % extract cues/features
        wp2Features = [wp2Features block];
    end
end

disp( '.' );
