function dataScaled = scaleData( data, translators, factors )

dataScaled = data - repmat( translators, size(data,1), 1 );
dataScaled = dataScaled .* repmat( factors, size(data,1), 1 );
