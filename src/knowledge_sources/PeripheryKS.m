classdef PeripheryKS < AbstractKS
    % PeripheryKS Aquires the current signal block and puts it onto the
    % blackboard
    
    properties (Access = public)
        dataObject;              % WP2 data object
        managerObject;           % WP2 manager object
    end
    
    methods
        function obj = PeripheryKS(blackboard, managerObject, dataObject)
            obj = obj@AbstractKS(blackboard);
            obj.dataObject = dataObject;
            obj.managerObject = managerObject;
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
                
                % WP2 Processing
                obj.managerObject.processChunk(signalBlock.signals);  % process new data
                
                % Get inner hair cell processing output
                ihcOut = cell(2, 1);
                ihcOut{1, 1} = obj.dataObject.innerhaircell{1}.Data;
                ihcOut{2, 1} = obj.dataObject.innerhaircell{2}.Data;
                
                % Add new periphery signal
                peripherySignal = PeripherySignal(signalBlock.blockNo, ...
                    signalBlock.headOrientation, ihcOut);
                
                % Remove old periphery signals from the bb
                if obj.blackboard.getNumPeripherySignals > 0
                    obj.blackboard.removePeripherySignals();
                end
                
                % Add periphery signal to the blackboard
                idx = obj.blackboard.addPeripherySignal(peripherySignal);
                
                % Mark current signal block as processed
                obj.blackboard.signalBlocks{1}.setSeenByPeripheryKS();
                
                % Display that KS has fired
                if obj.blackboard.verbosity > 0
                    fprintf('-------- PeripheryKS has fired.\n');
                end
                
                % Trigger event
                notify(obj.blackboard, 'NewPeripherySignal', BlackboardEventData(idx));
            end
        end
    end
end
