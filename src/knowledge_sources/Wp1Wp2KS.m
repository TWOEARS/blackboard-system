classdef Wp1Wp2KS < AbstractKS
    % Wp1Wp2KS Aquires the current signal and puts it through
    % wp2 processing. This is basically a simulator of functionality that
    % will be outside the blackboard on the deployment system
    
    properties (Access = public)
        managerObject;           % WP2 manager object - holds the signal buffer (data obj)
        wp1sim;                  % Scene simulator object
        timeStep = 0.02;         % basic time step, i.e. update rate
        maxBlockSize = 0.5;      % Default max block size 0.5 second
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
        function obj = Wp1Wp2KS( blackboard, wp1sim, timeStep, maxBlockSize )
            obj = obj@AbstractKS(blackboard);
            wp2dataObj = dataObject( [], wp1sim.SampleRate, 4, 1 );  % Last input (1) indicates a stereo signal
            obj.managerObject = manager( wp2dataObj );
            obj.wp1sim = wp1sim;
            if nargin >= 4
                obj.timeStep = timeStep;
            end
            if nargin >= 5
                obj.maxBlockSize = maxBlockSize;
            end
            obj.invocationMaxFrequency_Hz = 1.01 / timeStep;
        end

        %% KS logic
        function b = canExecute(obj)
            b = ~obj.wp1sim.isFinished();
        end

        function obj = execute(obj)
            % WP1 processing
            signalFrame = double(obj.wp1sim.getSignal(obj.timeStep));  % get data from wp1
            
            % WP2 Processing
            obj.managerObject.processChunk( signalFrame, 1 );  % process new data, append
            obj.blackboard.advanceSoundTimeIdx( ...
                size( signalFrame, 1 ) / obj.wp1sim.SampleRate );
            obj.blackboard.addData( 'headOrientation', mod( obj.wp1sim.getCurrentHeadOrientation(), 360 ) );
            
            if obj.blackboard.verbosity > 0
                fprintf('-------- Wp1Wp2KS has fired.\n');
            end
            
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
            reqHash = Wp1Wp2KS.getRequestHash( request, rParams );
            obj.blackboard.addWp2Signal( reqHash, reqSignal );
        end
        
    end
        
end
