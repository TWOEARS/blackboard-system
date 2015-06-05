classdef BlackboardSystem < handle

    properties (SetAccess = private)
        blackboard;
        blackboardMonitor;
        scheduler;
        robotConnect;
        dataConnect;
    end
        
    methods

        %% System Construction
        function obj = BlackboardSystem( verbosity )
            if nargin<1, verbosity=0; end
            obj.blackboard = Blackboard( verbosity );
            obj.blackboardMonitor = BlackboardMonitor( obj.blackboard );
            obj.scheduler = Scheduler( obj.blackboardMonitor );
        end

        function setRobotConnect( obj, robotConnect )
            obj.robotConnect = robotConnect;
        end

        function setDataConnect( obj, connectorClassName )
            % Connect to the Two!Ears Auditory Front-End module
            obj.dataConnect = obj.createKS( connectorClassName, {obj.robotConnect} );
        end
        
        function createProcsForKs( obj, ks )
            % Create processes for the Two!Ears Auditory Front-End KS
            obj.dataConnect.createProcsForDepKS( ks );
        end
        
        %% From xml
        function buildFromXml( obj, xmlName )
            bbsXml = xmlread( xmlName);
            bbsXmlElements = bbsXml.getElementsByTagName( 'blackboardsystem' ).item(0);

            buildDataConnectFromXml( obj, bbsXmlElements );
            kss = buildKSsFromXml( obj, bbsXmlElements );
            buildConnectionsFromXml( obj, bbsXmlElements, kss );
        end
        
        function buildDataConnectFromXml( obj, bbsXmlElements )
            elements = bbsXmlElements.getElementsByTagName( 'dataConnection' );
            ksType = char( elements.item(0).getAttribute('Type') );
            obj.setDataConnect( ksType );
        end
        
        function kss = buildKSsFromXml( obj, bbsXmlElements )
            kss = containers.Map( 'KeyType', 'char', 'ValueType', 'any' );
            ksElements = bbsXmlElements.getElementsByTagName( 'KS' );
            for k = 1:ksElements.getLength()
                ksName = char( ksElements.item(k-1).getAttribute('Name') );
                if kss.isKey( ksName )
                    error( '%s used twice as KS name!', ksName );
                end
                ksType = char( ksElements.item(k-1).getAttribute('Type') );
                ksParamElements = ksElements.item(k-1).getChildNodes.getElementsByTagName('Param');
                ksParams = {};
                for j = 1:ksParamElements.getLength()
                    ksParamType = char( ksParamElements.item(j-1).getAttribute('Type') );
                    ksParamStr = char( ksParamElements.item(j-1).getFirstChild.getData );
                    switch ksParamType
                        case 'char'
                            ksParams{end+1} = ksParamStr;
                        case 'double'
                            ksParams{end+1} = str2double( ksParamStr );
                        case 'int'
                            ksParams{end+1} = int64( str2double( ksParamStr ) );
                        case 'ref'
                            ksParams{end+1} = obj.(ksParamStr);
                    end
                end
                kss(ksName) = obj.createKS( ksType, ksParams );
            end
        end
        
        function buildConnectionsFromXml( obj, bbsXmlElements, kss )
            connElements = bbsXmlElements.getElementsByTagName( 'Connection' );
            for k = 1:connElements.getLength()
                mode = char( connElements.item(k-1).getAttribute('Mode') );
                srcElements = connElements.item(k-1).getChildNodes.getElementsByTagName('source');
                srcs = {};
                for j = 1:srcElements.getLength()
                    srcName = char( srcElements.item(j-1).getFirstChild.getData );
                    if kss.isKey( srcName )
                        srcs{end+1} = kss(srcName);
                    elseif isprop( obj, srcName )
                        srcs{end+1} = obj.(srcName);
                    else
                        error( 'Building connection: %s is not an existing source KS name!', srcName );
                    end
                end
                snks = {};
                snkElements = connElements.item(k-1).getChildNodes.getElementsByTagName('sink');
                for j = 1:snkElements.getLength()
                    snkName = char( snkElements.item(j-1).getFirstChild.getData );
                    if kss.isKey( snkName )
                        snks{end+1} = kss(snkName);
                    elseif isprop( obj, snkName )
                        snks{end+1} = obj.(snkName);
                    else
                        error( 'Building connection: %s is not an existing sink KS name!', snkName );
                    end
                end
                bindParams = {srcs, snks, mode};
                evntName = char( connElements.item(k-1).getAttribute('Event') );
                if ~isempty( evntName )
                    bindParams{end+1} = evntName;
                end
                obj.blackboardMonitor.bind( bindParams{:} );
            end
        end
        
        %% Add KS to the blackboard system
        function ks = addKS( obj, ks )
            ks.setBlackboardAccess( obj.blackboard, obj );
            if isa( ks, getfield( ?AuditoryFrontEndDepKS, 'Name' ) ) % using getfield to generate matlab error if class name changes.
                obj.createProcsForKs( ks );
            end
            obj.blackboard.KSs = [obj.blackboard.KSs {ks}];
        end
                   
        %% Create and add KS to the blackboard system
        function ks = createKS( obj, ksClassName, ksConstructArgs )
            if nargin < 3, ksConstructArgs = {}; end;
            ks = feval( ksClassName, ksConstructArgs{:} );
            ks = obj.addKS( ks );
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
