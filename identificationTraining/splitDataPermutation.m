function [lfolds, dfolds, idsfolds] = splitDataPermutation( l, d, ids, folds )

disp( 'splitting data into training/test folds.' );

uniqueIds = unique( ids );
perm = randperm( length( uniqueIds ) );
uniqueIdsPerm = uniqueIds(perm);

for i = 1: length( uniqueIds )
    uniqueClasses(i, 1) = { uniqueIds{i}(1:end-6) };
end
uniqueClasses = unique( uniqueClasses );

fprintf( '.' );

cfolds{folds} = [];
for i = 1:length( uniqueClasses )
    ucpos = strfind( uniqueIdsPerm, uniqueClasses{i} );
    ucposa = ~cellfun( @isempty, ucpos );
    thisClassIds = uniqueIdsPerm(ucposa);
    share = int64( size( thisClassIds, 1 )/folds );
    for j = 1:folds
        cfolds{j} = [cfolds{j}; thisClassIds(share*(j-1)+1:min(end,share*j))];
    end
end

fprintf( '.' );

dfolds{folds} = [];
lfolds{folds} = [];
idsfolds{folds} = [];
for j = 1:folds
    for i = 1:length( cfolds{j} )
        cpos = strfind( ids, cfolds{j}{i} );
        cposa = ~cellfun( @isempty, cpos );
        dfolds{j} = [dfolds{j}; d( cposa,: )];
        lfolds{j} = [lfolds{j}; l( cposa )];
        idsfolds{j} = [idsfolds{j}; ids( cposa )];
        ids( cposa ) = [];
        d( cposa,: ) = [];
        l( cposa ) = [];
    end
    fprintf( '.' );
end
    
fprintf( '.' );

for i = 1:folds
    perm = randperm( length(lfolds{i}) );
    lfolds{i} = lfolds{i}(perm);
    dfolds{i} = dfolds{i}(perm,:);
    idsfolds{i} = idsfolds{i}(perm);
end

disp( '.' );