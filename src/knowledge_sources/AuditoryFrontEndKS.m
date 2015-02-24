classdef AuditoryFrontEndKS < AbstractKS
    % AuditoryFrontEndKS Aquires the current ear signals and puts them through
    % Two!Ears Auditory Front-End processing. This is basically a simulator of
    % functionality thatmay (partially) be outside the blackboard on the
    % deployment system
    
    properties (SetAccess = private)
        managerObject;                  % Two!Ears Auditory Front-End manager object - holds the signal buffer (data obj)
        robotInterfaceObj;              % Scene simulator object
        timeStep = (512.0 / 44100.0);   % basic time step, i.e. update rate
        bufferSize_s = 10;
    end
    
    methods (Static)
        function regHash = getRequestHash( request, params )
            regHash = calcDataHash( {request, params} );
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
        function obj = AuditoryFrontEndKS( robotInterfaceObj )
            obj = obj@AbstractKS();
            dataObj = dataObject( [], robotInterfaceObj.SampleRate, obj.bufferSize_s, 2 );  % Last input (2) indicates a stereo signal
            obj.managerObject = manager( dataObj );
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
            % Two!Ears Binaural Simulator processing
            [signalFrame, processedTime] = obj.robotInterfaceObj.getSignal( obj.timeStep );
            
            % Two!Ears Auditory Front-End Processing
            obj.managerObject.processChunk( double(signalFrame), 1 );  % process new data, append (as indicated by 1)
            obj.blackboard.advanceSoundTimeIdx( processedTime );
            obj.blackboard.addData( ...
                'headOrientation', mod( obj.robotInterfaceObj.getCurrentHeadOrientation(), 360 )...
                );
            
            % Trigger event
            notify( obj, 'KsFiredEvent' );
        end

        %% KS utilities
        function createProcsForDepKS( obj, auditoryFrontEndDepKs )
            for z = 1:length( auditoryFrontEndDepKs.requests.r )
                obj.addProcessor( auditoryFrontEndDepKs.requests.r{z}, ...
                    auditoryFrontEndDepKs.requests.p{z} );
            end
        end
    
        function obj = addProcessor( obj, request, rParams )
            reqSignal = obj.managerObject.addProcessor( request, rParams );
            reqHash = AuditoryFrontEndKS.getRequestHash( request, rParams );
            obj.blackboard.addSignal( reqHash, reqSignal );
        end
        
    end
end
