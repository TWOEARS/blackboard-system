classdef SignalBlockKS < AbstractKS
    % SignalBlockKS Aquires the current signal block and puts it onto the
    % blackboard
    
    properties (SetAccess = private)
        sim;                     % Scene simulator object
        blockSize = 0.5;         % Default block size 0.5 second
        blockNo = 1;             % Current block number
    end
    
    methods
        function obj = SignalBlockKS(blackboard, sim, blockSize)
            obj = obj@AbstractKS(blackboard);
            obj.sim = sim;
            if exist('blockSize', 'var')
                obj.blockSize = blockSize;
            end
        end
        
        function b = canExecute(obj)
            if obj.sim.Sources.isEmpty()
                b = false;
            else
                b = obj.blackboard.readyForNextBlock;
            end
        end
        
        function execute(obj)
            
            % WP1 processing
            signalFrame = obj.sim.getSignal(obj.blockSize);  % get data from Buffer
            
            % Create signal block object
            signalBlock = SignalBlock(obj.blockNo, obj.blackboard.headOrientation, signalFrame);
            
            % Remove old signal blocks from the BB
            if obj.blackboard.getNumSignalBlocks > 0
                obj.blackboard.removeSignalBlock();
            end           
            
            % Add new signal block to the blackboard
            idx = obj.blackboard.addSignalBlock(signalBlock);
                        
            % Display that KS has fired
            if obj.blackboard.verbosity > 0
                fprintf('-------- SignalBlockKS has fired. Current block number is %d\n', obj.blockNo);
            end
            
            % Trigger event
            notify(obj.blackboard, 'NewSignalBlock', BlackboardEventData(idx));
            
            obj.blackboard.setReadyForNextBlock(false);
            obj.blockNo = obj.blockNo + 1;
        end
    end
end
