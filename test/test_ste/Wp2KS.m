classdef Wp2KS < AbstractKS
    % Wp2KS Aquires the current signal block and puts it through
    % wp2 processing
    
    properties (Access = public)
        wp2signals;              % WP2 process result handles
        managerObject;           % WP2 manager object
    end
    
    methods
        function obj = Wp2KS( blackboard, managerObject )
            obj = obj@AbstractKS(blackboard);
            obj.managerObject = managerObject;
        end
        
        function b = canExecute(obj)
            numSignalBlocks = obj.blackboard.getNumSignalBlocks;
            b = (numSignalBlocks ~= 0);
        end
        
        function execute(obj)
            % TODO: the following check seems duplicate of canExecute??
            % Check if there is any ear signal object on the bb
            if length(obj.blackboard.signalBlocks) < 1
                return
            else
                % Grab current signal block
                signalBlock = obj.blackboard.signalBlocks{1};
                
                % WP2 Processing
                obj.managerObject.processChunk(signalBlock.signals);  % process new data
                                
                % Mark current signal block as processed
                % TODO: change setSeenByPeripheryKS to sth else or change
                % "seen-by-system".
                obj.blackboard.signalBlocks{1}.setSeenByPeripheryKS();
                
                % Display that KS has fired
                if obj.blackboard.verbosity > 0
                    fprintf('-------- Wp2KS has fired.\n');
                end
                
                % Trigger event
                notify( obj.blackboard, 'NewWp2Signal', BlackboardEventData(idx) );
            end
        end
    end
end
