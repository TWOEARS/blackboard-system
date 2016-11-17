classdef IntegrateIdentitiesKS < AbstractKS
    
    properties (SetAccess = private)
        maxObjectsAtLocation;
        classThresholds;
        generalThreshold;
        integratedMap; % absolute
        integratedNsrcs;
        leakFactor;
        hypSpread;
        npdf;
    end

    methods
        function obj = IntegrateIdentitiesKS( leakFactor, hypSpread, maxObjectsAtLocation, classThresholds, generalThreshold )
            obj@AbstractKS();
            obj.setInvocationFrequency(inf);
            if nargin < 1 || isempty( leakFactor )
                leakFactor = 0.5; 
            end
            if nargin < 2 || isempty( hypSpread )
                hypSpread = 15; 
            end
            x = -3*hypSpread : 1 : 3*hypSpread;
            npdf = normpdf( x, 0, hypSpread );
            if nargin < 3 || isempty( maxObjectsAtLocation )
                maxObjectsAtLocation = inf; 
            end
            if nargin < 4 || isempty( classThresholds )
                classThresholds = struct();
            end
            if nargin < 5 || isempty( generalThreshold )
                generalThreshold = 0.5*max( npdf );
            end
            obj.leakFactor = leakFactor;
            obj.hypSpread = hypSpread;
            obj.maxObjectsAtLocation = maxObjectsAtLocation;
            obj.classThresholds = classThresholds;
            obj.generalThreshold = generalThreshold;
            obj.integratedNsrcs = 0;
            obj.integratedMap = struct();
            obj.npdf = npdf;
        end
        
        function setInvocationFrequency( obj, newInvocationFrequency_Hz )
            obj.invocationMaxFrequency_Hz = newInvocationFrequency_Hz;
        end
        
        function [b, wait] = canExecute( obj )
            b = true;
            wait = false;
        end
        
        function execute(obj)
            % get all identityHypotheses
            idloc = obj.blackboard.getData( ...
                                  'identityHypotheses', obj.trigger.tmIdx).data;
            labels = {idloc.label};
            ps = [idloc.p]; 
            ds = [idloc.d];
            
            notify( obj, 'KsFiredEvent', BlackboardEventData( obj.trigger.tmIdx ) );
        end
            
        % Visualisation
        function visualise(obj)
            if ~isempty(obj.blackboardSystem.locVis)
                idloc = obj.blackboard.getData( ...
                    'identityHypotheses', obj.trigger.tmIdx);
                if isempty( idloc )
                    obj.blackboardSystem.locVis.setLocationIdentity(...
                        {}, {}, {}, {});
                else
                    idloc = idloc.data;
                    obj.blackboardSystem.locVis.setIdentity(...
                        {idloc(:).label}, {idloc(:).p}, {idloc(:).d});
                end
            end
        end
    end
    
    methods (Access = protected)        

        function ds = applyClassSpecificThresholds( obj, labels, ps )
            ds = zeros( size( ps ) );
            for ii = 1 : numel( labels )
                if isfield( obj.classThresholds, labels{ii} )
                    thr = obj.classThresholds.(labels{ii});
                else
                    thr = obj.generalThreshold;
                end
                if ps(ii) >= thr
                    ds(ii) = 1;
                else
                    ds(ii) = -1;
                end
            end
        end

        function locMaxedObjects = onlyAllowNobjectsPerLocation( obj, locMaxedObjects )
            for ll = 1 : numel( locMaxedObjects )
                locObjs = locMaxedObjects{ll};
                locObjs.labels(obj.maxObjectsAtLocation+1:end) = [];
                locObjs.ps(obj.maxObjectsAtLocation+1:end) = [];
                locObjs.ds(obj.maxObjectsAtLocation+1:end) = [];
                locMaxedObjects{ll} = locObjs;
            end
        end
        
    end
    
    methods (Static)
    end % static methods
end
