function createWp2Data( soundsDir, className, niState, checkForPrecomputedData )

[soundFileNames, soundFileNamesOther] = makeSoundLists( soundsDir, className );
soundFileNamesAll = [soundFileNames; soundFileNamesOther];

% for every sound file:
for i = 1:length( soundFileNamesAll )

    % do wp2 processing 
    if checkForPrecomputedData && exist( [soundFileNamesAll{i} '.wp2.mat'], 'file' )
        disp( [soundFileNamesAll{i} '.wp2.mat already existing'] );
    else
        disp( ['creating and saving ' soundFileNamesAll{i} '.wp2.mat'] );
        wp2Features = wp2processSound( soundFileNamesAll{i}, niState );
        save( [soundFileNamesAll{i} '.wp2.mat'], 'wp2Features', 'niState' );
    end
   
end
