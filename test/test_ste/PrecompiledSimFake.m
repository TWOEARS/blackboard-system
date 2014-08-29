classdef PrecompiledSimFake < handle
    
    properties (SetAccess = private)
        sceneSound;
        SampleRate;
        currentPos;
    end
    
    methods
        function obj = PrecompiledSimFake( sceneSound, fs )
            obj.sceneSound = sceneSound;
            obj.SampleRate = fs;
            obj.currentPos = 1;
        end
        
        function fini = isFinished( obj )
            fini = (obj.currentPos > length( obj.sceneSound ));
        end
        
        function signal = getSignal( obj, blockSize )
            blockSizeSamples = blockSize * obj.SampleRate;
            blockEnd = min( length( obj.sceneSound ), obj.currentPos + blockSizeSamples - 1 );
            signal = obj.sceneSound(obj.currentPos:blockEnd,:);
            if length( signal ) < blockSizeSamples
                signal = [signal; zeros( blockSizeSamples - length( signal ), 2 )];
            end
            obj.currentPos = blockEnd + 1;
            fprintf( 'time: %.3gs\n', obj.currentPos / obj.SampleRate );
        end
    end
    
end
