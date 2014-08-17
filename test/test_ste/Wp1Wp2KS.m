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
        function obj = Wp1Wp2KS( blackboard, fs, wp1sim, timeStep, maxBlockSize )
            obj = obj@AbstractKS(blackboard);
            wp2dataObj = dataObject( [], fs, 1 );  % Last input (1) indicates a stereo signal
            obj.managerObject = manager( wp2dataObj );
            obj.wp1sim = wp1sim;
            if nargin >= 4
                obj.timeStep = timeStep;
            end
            if nargin >= 5
                obj.maxBlockSize = maxBlockSize;
            end
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
            
            %TODO: this should be implemented in wp2.
            %obj.ltrimSignalBuffersToMaxBlocksize();
            
            if obj.blackboard.verbosity > 0
                fprintf('-------- Wp1Wp2KS has fired.\n');
            end
            
            % Trigger event
            notify( obj.blackboard, 'NewWp2Signal' );
        end

        %% KS utilities
        function obj = addProcessor( obj, request, rParams )
            reqSignal = obj.managerObject.addProcessor( request, rParams );
            reqHash = Wp1Wp2KS.getRequestHash( request, rParams );
            obj.blackboard.addWp2Signal( reqHash, reqSignal );
        end
        
        function obj = ltrimSignalBuffersToMaxBlocksize( obj )
            % cut obj.managerObject.InputList{1,:}
            % cut obj.managerObject.OutputList{:,:}
            disp( 'not implemented' );
        end
        
    end
end
