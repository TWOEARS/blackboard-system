classdef BlackboardSystem < handle

    properties (SetAccess = private)
        blackboard;
        blackboardMonitor;
        scheduler;
        robotConnect;
        wp2DataConnect;
    end
        
    methods

        %% System Construction
        function obj = BlackboardSystem()
            obj.blackboard = Blackboard( 1 );
            obj.blackboardMonitor = BlackboardMonitor( obj.blackboard );
            obj.scheduler = Scheduler( obj.blackboardMonitor );
        end

        function setRobotConnect( obj, robotConnect )
            obj.robotConnect = robotConnect;
        end

        function setWp2DataConnect( obj, wp2ConnectorClassName )
            obj.wp2DataConnect = feval( wp2ConnectorClassName, obj.blackboard, obj.robotConnect );
            obj.addKS( obj.wp2DataConnect );
        end

        
        function createWp2ProcsForKs( obj, ks )
            obj.wp2DataConnect.createProcsForDepKS( ks );
        end
        
        %% Add KS to the blackboard system
        function addKS( obj, ks )
            ks.setBlackboardAccess( obj.blackboard );
            if isa( ks, getfield( ?Wp2DepKS, 'Name' ) ) % using getfield to generate matlab error if class name changes.
                obj.createWp2ProcsForKs( ks );
            end
            obj.blackboard.KSs = [obj.blackboard.KSs {ks}];
        end
                   
        %% Get number of KSs
        function n = numKSs( obj )
            n = length( obj.blackboard.KSs );
        end
        

        %% System Execution
        
        function run( obj )
            while ~obj.robotConnect.isFinished()
                obj.scheduler.processAgenda();
                notify( obj.scheduler, 'AgendaEmpty' );
            end
        end
        
    end
    
end
