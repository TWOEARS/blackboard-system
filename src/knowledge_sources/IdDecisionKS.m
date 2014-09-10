classdef IdDecisionKS < AbstractKS
    
    properties (SetAccess = private)
        minSources = 0;
        maxSources = 1;
    end
    
    methods
        function obj = IdDecisionKS( blackboard, minSources, maxSources )
            obj = obj@AbstractKS( blackboard );
            obj.minSources = minSources;
            obj.maxSources = maxSources;
        end
        
        function delete( obj )
        end
        
        function b = canExecute( obj )
            b = true;
        end
        
        function execute( obj )
            if obj.blackboard.verbosity > 0
                fprintf('-------- IdDecisionKS has fired.\n');
            end
            
            
            sndTmIdx = max( cell2mat( keys( obj.blackboard.data ) ) ); % TODO: consider "history" case
            idHyps = obj.blackboard.data(sndTmIdx).identityHypotheses;
            [~,idx] = max( [idHyps.p] );
            maxProbHyp = idHyps(idx);
            
            if maxProbHyp.p > 0.44
                    fprintf( 'Identity Decision: %s with %i%% probability.\n', ...
                        maxProbHyp.label, int16(maxProbHyp.p*100) );
                obj.blackboard.addData( 'identityDecision', maxProbHyp, false );
                notify( obj.blackboard, 'NewIdentityDecision', BlackboardEventData(0) );
            end
        end
    end
end
