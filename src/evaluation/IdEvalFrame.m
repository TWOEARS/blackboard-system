classdef IdEvalFrame < handle
    
    properties (SetAccess = private)
        bb;
        idError;
        idTruth;
    end
    
    methods
        
        function obj = IdEvalFrame( blackboard )
            obj.bb = blackboard;
        end
        
        function readIdTruth( obj, sourceWavName, zeroOffsetLength_s )
            obj.idTruth.class = IdEvalFrame.readEventClass( sourceWavName );
            obj.idTruth.onsetsOffsets = ...
                IdEvalFrame.readOnOffAnnotations( sourceWavName ) + zeroOffsetLength_s;
            obj.idTruth.onsetsOffsets(obj.idTruth.onsetsOffsets(:,1) == inf,:) = [];
            obj.idTruth.onsetsOffsets(obj.idTruth.onsetsOffsets(:,2) == inf,:) = [];
        end
        
        function ide = calcIdError( obj, idClass )
            idDecs = obj.bb.getData( 'identityDecision' );
            idDecs = idDecs(arrayfun(@(x)(strcmp(x.data.label,idClass)),idDecs));
            if ~isempty( idDecs )
                iddTm = [idDecs.sndTmIdx];
                iddDat = [idDecs.data];
                iddOnOffs = [(iddTm - [iddDat.concernsBlocksize_s]); iddTm]';
            else
                iddOnOffs = zeros(0,2);
            end
            k = 1;
            while k < size( iddOnOffs, 1 )
                if iddOnOffs(k,2) >= iddOnOffs(k+1,1)
                    iddOnOffs(k,2) = iddOnOffs(k+1,2);
                    iddOnOffs(k+1,:) = [];
                else
                    k = k + 1;
                end
            end
            
            ide.testposTime = sum( iddOnOffs(:,2) - iddOnOffs(:,1) );
            ide.testnegTime = obj.bb.currentSoundTimeIdx - ide.testposTime;
            ide.condposTime = sum( obj.idTruth.onsetsOffsets(:,2) - obj.idTruth.onsetsOffsets(:,1) );
            ide.condnegTime = obj.bb.currentSoundTimeIdx - ide.condposTime;
            ide.trueposTime = 0;
            for k = 1:size(iddOnOffs,1)
                intersectOffs = min( iddOnOffs(k,2), obj.idTruth.onsetsOffsets(:,2) );
                intersectOns = max( iddOnOffs(k,1), obj.idTruth.onsetsOffsets(:,1) );
                overlaps = max( 0, intersectOffs - intersectOns );
                ide.trueposTime = ide.trueposTime + sum( overlaps );
            end
            ide.falseposTime = ide.testposTime - ide.trueposTime;
            ide.truenegTime = ide.condnegTime - ide.falseposTime;
            ide = IdEvalFrame.meanErrors( ide );
            obj.idError = ide;
        end
    end
   
    %% Static utils
    methods (Static)
        
        function eventClass = readEventClass( soundFileName )
            fileSepPositions = strfind( soundFileName, filesep );
            if isempty( fileSepPositions )
                error( 'Cannot infer sound event class - possibly because "%d" is not a full path.', soundFileName );
            end
            classPos1 = fileSepPositions(end-1);
            classPos2 = fileSepPositions(end);
            eventClass = soundFileName(classPos1+1:classPos2-1);
        end
        
        function onsetOffsets = readOnOffAnnotations( soundFileName )
            annotFid = fopen( [soundFileName '.txt'] );
            if annotFid ~= -1
                onsetOffsets = [];
                while 1
                    annotLine = fgetl( annotFid );
                    if ~ischar( annotLine ), break, end
                    onsetOffsets(end+1,:) = sscanf( annotLine, '%f' );
                end
            else
                warning( sprintf( 'label annotation file not found: %s. Assuming no events.', soundFileName ) );
                onsetOffsets = [ inf, inf ];
            end
        end
        
        function errors = meanErrors( errors )
            errors(1).trueposTime = sum([errors.trueposTime]);
            errors(1).condposTime = sum([errors.condposTime]);
            errors(1).condnegTime = sum([errors.condnegTime]);
            errors(1).testposTime = sum([errors.testposTime]);
            errors(1).truenegTime = sum([errors.truenegTime]);
            errors(1).testnegTime = sum([errors.testnegTime]);
            errors(2:end) = [];
            errors.sensitivity = errors.trueposTime / errors.condposTime;
            errors.pospredval = errors.trueposTime / errors.testposTime;
            errors.specificity = errors.truenegTime / errors.condnegTime;
            errors.negpredval = errors.truenegTime / errors.testnegTime;
            errors.acc = (errors.trueposTime + errors.truenegTime) / ...
                (errors.condposTime + errors.condnegTime);
        end
        
    end
    
end