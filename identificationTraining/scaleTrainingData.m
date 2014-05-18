function [trInstancesScaled, featureTranslators, featureFactors] = scaleTrainingData( trInstances )

% translate data to 0 mean
featureTranslators = mean( trInstances );

% transform data to 1 std
featureFactors = 1 ./ std( trInstances );

trInstancesScaled = scaleData( trInstances, featureTranslators, featureFactors );
