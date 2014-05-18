function l = makeLabels( soundFile, niState, nBlocks )

fprintf( 'labels ' );

%read annotations
annotFid = fopen( [soundFile '.txt'] );
if annotFid ~= -1
    annotLine = fgetl( annotFid );
    onsetOffset = sscanf( annotLine, '%f' );
else
    onsetOffset = [ inf, inf ];
end
eventLength = onsetOffset(2) - onsetOffset(1);
maxBlockSoundLength = min( niState.simParams.blockSize, eventLength );


% split in blocks, for every block:
l = zeros( nBlocks, 1 );
for blockno = 1:nBlocks 

    fprintf( '.' );

    % extract label and add to trLabels
    blockOnset = (blockno - 1) * niState.shiftSize;
    blockOffset = blockOnset + niState.simParams.blockSize;
    soundInBlockLength = min( blockOffset, onsetOffset(2) ) - max( blockOnset, onsetOffset(1) );
    ratioBlockToSoundEvent = soundInBlockLength / maxBlockSoundLength;
    blockIsSoundEvent = ratioBlockToSoundEvent > 0.66;
    l(blockno,1) = blockIsSoundEvent;
end

if annotFid ~= -1
    fclose( annotFid );
end

%scaling l to [-1..1]
l = (l * 2) - 1;

