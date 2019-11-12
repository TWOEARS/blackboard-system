classdef AudioWriteKS < AuditoryFrontEndDepKS

    properties (SetAccess = private)
        signalBuffer = [];
        robot
        pathToSoundFile
        samplingRate
        writtenAt = 0;
    end
    
    properties (Access = private)
        firstCall = true;
    end

    methods
        function obj = AudioWriteKS(robot, pathToSoundFile)
            requests{1}.name = 'time';
            requests{1}.params = genParStruct();
            obj = obj@AuditoryFrontEndDepKS(requests);
            obj.invocationMaxFrequency_Hz = Inf;
            obj.robot = robot;
            obj.pathToSoundFile = pathToSoundFile;
        end
        
        function delete(obj)
            obj.writeEarsignals();
        end

        function [b, wait] = canExecute(obj)
            b = obj.hasEnoughNewSignal(obj.blackboardSystem.dataConnect.timeStep);
            wait = false;
        end

        function execute(obj)
            if obj.firstCall
                obj.samplingRate = obj.blackboardSystem.dataConnect.afeFs;
                obj.firstCall = false;
            end
%             earSignals = obj.getNextSignalBlock(1, obj.blackboardSystem.dataConnect.timeStep);
            earSignals = obj.getSignalBlock( 1, ...
                                             [obj.lastBlockEnd(1), obj.trigger.tmIdx], ...
                                             false, false );
            obj.signalBuffer = [obj.signalBuffer; [earSignals{1}, earSignals{2}]];
        end
        
        function writeEarsignals( obj )
            if obj.lastBlockEnd > obj.writtenAt
                obj.signalBuffer = obj.signalBuffer ./ max( abs( obj.signalBuffer(:) ) );
                audiowrite(obj.pathToSoundFile, obj.signalBuffer, obj.samplingRate);
                obj.writtenAt = obj.lastBlockEnd;
            end
        end
            
    end
end
