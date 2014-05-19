classdef SignalBlockKS < AbstractKS
    % SignalBlockKS Aquires the current signal block and puts it onto the
    % blackboard
    
    properties (SetAccess = private)
        scene;                   % Scene object to be rendered
        blockNo = 1;             % Current block number
        renderedSignals;         % Rendered ear signals
    end
    
    methods
        function obj = SignalBlockKS(blackboard)
            obj = obj@AbstractKS(blackboard);
            obj.scene = obj.blackboard.scene;
            obj.renderedSignals = zeros(obj.scene.numSamples + ...
                obj.scene.frameLength + obj.scene.head.numSamples - 1, 2);
        end
        
        function b = canExecute(obj)
            if obj.blockNo <= obj.scene.timeSteps
                b = obj.blackboard.readyForNextBlock;
            else
                b = false;
            end
        end
        
        function execute(obj)
            
            % Get new processed signal
            signalProc = obj.scene.getFrame(obj.blockNo);
            
            % Get frame indices
            startIndex = (obj.blockNo - 1) * obj.scene.frameShift + 1;
            endIndex = startIndex + size(signalProc, 1) - 1;
            
            % Render output signal via overlap/add
            for l = 1 : 2
                obj.renderedSignals(startIndex : endIndex, l) = ...
                    obj.renderedSignals(startIndex : endIndex, l) ...
                    + signalProc(:, l);
            end
            
            % Get current preprocessed left/right ear signals
            signalL = obj.renderedSignals(startIndex : startIndex + ...
                obj.scene.frameLength - 1, 1);
            signalR = obj.renderedSignals(startIndex : startIndex + ...
                obj.scene.frameLength - 1, 2);
            
            signalFrame = [signalR signalL];
            
            % Create signal block object
            signalBlock = SignalBlock(obj.blockNo, obj.blackboard.headOrientation, signalFrame);
            
            % Remove old signal blocks from the BB
            if obj.blackboard.getNumSignalBlocks > 0
                obj.blackboard.removeSignalBlock();
            end           
            
            % Add new signal block to the blackboard
            idx = obj.blackboard.addSignalBlock(signalBlock);
                        
            % Display that KS has fired
            fprintf('-------- SignalBlockKS has fired. Current block number is %d\n', obj.blockNo);
           
            % Trigger event
            notify(obj.blackboard, 'NewSignalBlock', BlackboardEventData(idx));
            
            obj.blackboard.setReadyForNextBlock(false);
            obj.blockNo = obj.blockNo + 1;
        end
    end
end
