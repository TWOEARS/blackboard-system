function [soundFileNames, soundFileNamesOther] = makeSoundLists( soundsDir, className )

% find all sound files in class dir
classDir = [soundsDir '\' className];
soundFileNames = dir( [classDir '\*.wav'] );
soundFileNames = {soundFileNames(:).name}';
soundFileNames = strcat( [classDir '\'], soundFileNames );

% find all sound files in other class dirs
soundDirNames = dir( soundsDir );
for i = 1: size( soundDirNames, 1 )
    if strcmpi( soundDirNames(i).name, '.' ) == 1; continue; end;
    if strcmpi( soundDirNames(i).name, '..' ) == 1; continue; end;
    if strcmpi( soundDirNames(i).name, className ) == 1; continue; end;
    if soundDirNames(i).isdir ~= 1; continue; end;
    soundDirTmp = [soundsDir '\' soundDirNames(i).name '\'];
    soundFileNamesOtherTmp = dir( [soundDirTmp '*.wav'] ); 
    soundFileNamesOtherTmp = {soundFileNamesOtherTmp(:).name}';
    soundFileNamesOtherTmp = strcat( soundDirTmp, soundFileNamesOtherTmp );
    if ~exist( 'soundFileNamesOther', 'var' ); soundFileNamesOther = soundFileNamesOtherTmp; 
    else soundFileNamesOther = [soundFileNamesOther ; soundFileNamesOtherTmp]; end;
end
