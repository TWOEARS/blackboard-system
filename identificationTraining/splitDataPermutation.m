function [ltr, lte, dtr, dte, idstr, idste] = splitDataPermutation( l, d, ids, trShare )

disp( 'splitting data into training and test set.' );

uniqueIds = unique( ids );

for i = 1: length( uniqueIds )
    uniqueClasses(i, 1) = { uniqueIds{i}(1:end-6) };
end
uniqueClasses = unique( uniqueClasses );

perm = randperm( length( uniqueIds ) );
idsp = uniqueIds(perm);

fprintf( '.' );

ctr = [];
cte = [];
for i = 1:length( uniqueClasses )
    thisClassIds = [];
    for j = 1:length( idsp )
        if isempty( strfind( idsp{j}, uniqueClasses{i} ) )
            continue;
        end
        thisClassIds = [thisClassIds; {idsp{j}}];
    end
    share = int64( trShare *  size( thisClassIds, 1 ) );
    ctr = [ctr; thisClassIds(1:share,:)];
    cte = [cte; thisClassIds(share+1:end,:)];
end

fprintf( '.' );

dtr = [];
ltr = [];
idstr = [];
dte = [];
lte = [];
idste = [];
for i = 1:length( ctr )
    for j = 1:length( ids )
        if strcmp( ids{j}, ctr{i} ) == 1
            dtr = [dtr; d(j,:)];
            ltr = [ltr; l(j)];
            idstr = [idstr; ids(j)];
        end
    end 
end

fprintf( '.' );

for i = 1:length( cte )
    for j = 1:length( ids )
        if strcmp( ids{j}, cte{i} ) == 1
            dte = [dte; d(j,:)];
            lte = [lte; l(j)];
            idste = [idste; ids(j)];
        end
    end 
end
    
fprintf( '.' );

perm = randperm( length(ltr) );
ltr = ltr(perm);
dtr = dtr(perm,:);
idstr = idstr(perm);

perm = randperm( length(lte) );
lte = lte(perm);
dte = dte(perm,:);
idste = idste(perm);

disp( '.' );