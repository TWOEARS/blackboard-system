classdef PrecompiledSimFake < handle
    
    properties (SetAccess = private)
        sceneSound;
        fs;
        currentPos;
    end
    
    methods
        function obj = PrecompiledSimFake( sceneSound, fs )
            obj.sceneSound = sceneSound;
            obj.fs = fs;
            obj.currentPos = 1;
        end
        
        function fini = isFinished( obj )
            fini = (obj.currentPos > length( obj.sceneSound ));
        end
        
        function signal = getSignal( obj, blockSize )
            blockSizeSamples = blockSize * obj.fs;
            blockEnd = min( length( obj.sceneSound ), obj.currentPos + blockSizeSamples );
            signal = obj.sceneSound(obj.currentPos:blockEnd,:);
            if length( signal ) < blockSizeSamples
                signal = [signal zeros( 2, blockSizeSamples - length( signal ) )];
            end
            obj.currentPos = blockEnd + 1;
        end
    end
    
end
