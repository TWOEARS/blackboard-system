classdef SignalBlockKS < AbstractKS
    % SignalBlockKS Aquires the current signal block and puts it onto the
    % blackboard
    
    properties (SetAccess = private)
        sim;                     % Scene simulator object
        blockNo = 1;             % Current block number
    end
    
    methods
        function obj = SignalBlockKS(blackboard, sim)
            obj = obj@AbstractKS(blackboard);
            obj.sim = sim;
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
            obj.sim.set('Refresh',true);  % Refresh Positions 
            obj.sim.set('Process',true);  % Process Ear Signals
            signalFrame = double(obj.sim.Sinks.getData(obj.sim.BlockSize));  % get data from Buffer
            obj.sim.Sinks.removeData(obj.sim.BlockSize);  % remove data from Buffer
            
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
