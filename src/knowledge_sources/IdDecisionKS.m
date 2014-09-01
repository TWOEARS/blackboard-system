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
            
            
            idHyps = obj.blackboard.identityHypotheses;
            lastIdHypSndTmIdx = idHyps{1,end};
            curIdHyps = [idHyps{2,cell2mat(idHyps(1,:))==lastIdHypSndTmIdx}];
            [~,idx] = max( [curIdHyps.p] );
            maxProbHyp = curIdHyps(idx);
            
            if maxProbHyp.p > 0.44
                fprintf( 'Identity Decision: %s with %i%% probability.\n', ...
                    maxProbHyp.label, int16(maxProbHyp.p*100) );
                identDec = IdentityHypothesis( maxProbHyp.label, maxProbHyp.p );
                idx = obj.blackboard.addIdentityDecision( identDec );
                notify( obj.blackboard, 'NewIdentityDecision', BlackboardEventData(idx) );
            end
        end
    end
end
