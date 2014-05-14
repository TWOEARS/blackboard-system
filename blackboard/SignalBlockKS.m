classdef SignalBlockKS < AbstractKS
    % SignalBlockKS Aquires the current signal block and puts it onto the
    % blackboard
    
    properties (SetAccess = private)
        scene;                   % Scene object to be rendered
        blockNo = 1;             % Current block number
        renderedSignals;         % Rendered ear signals
        blockSize                % Size of a signal block
        numBlocks                % Number of blocks to render
        numFrames                % Number of frames per block
        frameLength              % Frame length
        frameShift               % Frame shift
    end
    
    methods
        function obj = SignalBlockKS(blackboard, sp)
            obj = obj@AbstractKS(blackboard);
            obj.scene = obj.blackboard.scene;
            obj.renderedSignals = zeros(obj.scene.numSamples + ...
                obj.scene.frameLength + obj.scene.head.numSamples - 1, 2);
            obj.blockSize = sp.blockSize * sp.fsHz;
            
            obj.frameLength = sp.winSizeSec * sp.fsHz;
            obj.frameShift = sp.hopSizeSec * sp.fsHz;
            
            % Compute number of blocks
            obj.numBlocks = ceil(obj.scene.numSamples / obj.blockSize);
            
            % Compute number of frames
            overlap = (sp.winSizeSec - sp.hopSizeSec) * sp.fsHz;
            
            obj.numFrames = ceil((obj.blockSize - overlap) / ...
                (sp.winSizeSec * sp.fsHz - overlap));
        end
        
        function b = canExecute(obj)
            if obj.blockNo <= obj.numBlocks
                b = obj.blackboard.readyForNextBlock;
            else
                b = false;
            end
        end
        
        function execute(obj)
            % Get current preprocessed left/right ear signals
            blockStart = (obj.blockNo - 1) * obj.blockSize + 1;
            blockEnd = min(blockStart + obj.blockSize - 1);
            
            % Compute signal frames and create block
            for k = 1 : obj.numFrames
                % Get signal indices
                startIndex = (blockStart - 1) + ...
                    (k - 1) * obj.frameShift + 1;
                endIndex = startIndex + obj.scene.convLength - 1;
                
                % Get new processed signal
                signalProc = obj.scene.getFrame((obj.blockNo - 1) * ...
                    obj.numFrames + k);
               
                % Render output signal via overlap/add
                for l = 1 : 2
                    obj.renderedSignals(startIndex : endIndex, l) = ...
                        obj.renderedSignals(startIndex : endIndex, l) ...
                        + signalProc(:, l);
                end
            end
           
            signalR = obj.renderedSignals(blockStart : blockEnd, 1);
            signalL = obj.renderedSignals(blockStart : blockEnd, 2);
            
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
            
            % Increment block number
            if obj.blockNo <= obj.numBlocks
                obj.blockNo = obj.blockNo + 1;
            end
        end
    end
end
