classdef PeripheryKS < AbstractKS
    % PeripheryKS Aquires the current signal block and puts it onto the
    % blackboard
    
    properties (Access = private)
        simParams;               % Simulation parameters for peripheral processing
        wp2States;               % Parameters regarding the WP2 processing
    end
    
    methods
        function obj = PeripheryKS(blackboard, simParams, wp2States)
            obj = obj@AbstractKS(blackboard);
            obj.simParams = simParams;
            obj.wp2States = wp2States;
        end
        
        function b = canExecute(obj)
            b = false;
            
            numSignalBlocks = obj.blackboard.getNumSignalBlocks;
            
            if numSignalBlocks == 0
                return
            else
                b = true;
            end
        end
        
        function execute(obj)
            % Check if there is any ear signal object on the bb
            if length(obj.blackboard.signalBlocks) < 1
                return
            else
                % Grab current signal block
                signalBlock = obj.blackboard.signalBlocks{1};
                
                earSignals = signalBlock.signals;
                
                wp2Signal = process_WP2_signals(earSignals, ...
                    obj.simParams.fsHz, obj.wp2States);
                
                peripherySignal = PeripherySignal(signalBlock.blockNo, signalBlock.headOrientation, wp2Signal);
                
                % Remove old periphery signals from the bb
                if obj.blackboard.getNumPeripherySignals > 0
                    obj.blackboard.removePeripherySignals();
                end
                
                % Add periphery signal to the blackboard
                idx = obj.blackboard.addPeripherySignal(peripherySignal);
                
                obj.blackboard.signalBlocks{1}.setSeenByPeripheryKS();
                
                % Display that KS has fired
                if obj.blackboard.verbosity > 0
                    fprintf('-------- PeripheryKS has fired.\n');
                end
                
                % Trigger event
                notify(obj.blackboard, 'NewPeripherySignal', BlackboardEventData(idx));
            end
            
            % JUST FOR DEBUGGING
            %obj.blackboard.setReadyForNextFrame(true);
        end
    end
end
