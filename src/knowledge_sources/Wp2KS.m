classdef Wp2KS < AbstractKS
    % Wp2KS Aquires the current ear signals and puts them through
    % wp2 processing. This is basically a simulator of functionality that
    % may (partially) be outside the blackboard on the deployment system
    
    properties (SetAccess = private)
        managerObject;           % WP2 manager object - holds the signal buffer (data obj)
        robotInterfaceObj;                  % Scene simulator object
        timeStep = (512.0 / 44100.0);         % basic time step, i.e. update rate
        wp2BufferSize_s = 10;
    end
    
    methods (Static)
        function regHash = getRequestHash( request, params )
            regHash = DataHash( {request, params} );
        end
        
        function plotSignalBlocks( bb, evnt )
            sigBlock = bb.signalBlocks{evnt.data};
            subplot(4, 4, [15, 16])
            plot(sigBlock.signals(:,1));
            axis tight; ylim([-1 1]);
            xlabel('k');
            title(sprintf('Block %d, head orientation: %d deg, left ear waveform', sigBlock.blockNo, sigBlock.headOrientation), 'FontSize', 12);
            
            subplot(4, 4, [13, 14])
            plot(sigBlock.signals(:,2));
            axis tight; ylim([-1 1]);
            xlabel('k');
            title(sprintf('Block %d, head orientation: %d deg, right ear waveform', sigBlock.blockNo, sigBlock.headOrientation), 'FontSize', 12);
        end
    end
    
    methods
        %% constructor
        function obj = Wp2KS( robotInterfaceObj )
            obj = obj@AbstractKS();
            wp2dataObj = dataObject( [], robotInterfaceObj.SampleRate, obj.wp2BufferSize_s, 1 );  % Last input (1) indicates a stereo signal
            obj.managerObject = manager( wp2dataObj );
            obj.robotInterfaceObj = robotInterfaceObj;
            obj.timeStep = obj.robotInterfaceObj.BlockSize / obj.robotInterfaceObj.SampleRate;
            obj.invocationMaxFrequency_Hz = inf;
        end

        %% KS logic
        function [b, wait] = canExecute(obj)
            b = ~obj.robotInterfaceObj.isFinished();
            wait = false;
        end

        function obj = execute(obj)
            % WP1 processing
            [signalFrame, processedTime] = obj.robotInterfaceObj.getSignal( obj.timeStep );
            
            % WP2 Processing
            obj.managerObject.processChunk( double(signalFrame), 1 );  % process new data, append
            obj.blackboard.advanceSoundTimeIdx( processedTime );
            obj.blackboard.addData( ...
                'headOrientation', mod( obj.robotInterfaceObj.getCurrentHeadOrientation(), 360 )...
                );
            
            % Trigger event
            notify( obj, 'KsFiredEvent' );
        end

        %% KS utilities
        function createProcsForDepKS( obj, wp2depKs )
            for z = 1:length( wp2depKs.wp2requests.r )
                obj.addProcessor( wp2depKs.wp2requests.r{z}, wp2depKs.wp2requests.p{z} );
            end
        end
    
        function obj = addProcessor( obj, request, rParams )
            reqSignal = obj.managerObject.addProcessor( request, rParams );
            reqHash = Wp2KS.getRequestHash( request, rParams );
            obj.blackboard.addWp2Signal( reqHash, reqSignal );
        end
        
    end
end
