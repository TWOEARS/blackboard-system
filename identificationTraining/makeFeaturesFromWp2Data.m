function instances = makeFeaturesFromWp2Data( wp2Data, niState )

fprintf( 'features ' );
 
% split in blocks, for every block:
nBlocks = size( wp2Data, 2 );
for blockno = 1:nBlocks 
    fprintf( '.' );
    features = niState.featureFunction( niState.featureFunctionParam, wp2Data(blockno).data );
    if blockno == 1
        lenFeatureVector = length( features );
        instances = zeros( nBlocks, lenFeatureVector );
    end
    instances(blockno,:) = features;
end

