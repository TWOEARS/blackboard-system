classdef AudioWriteKS < AuditoryFrontEndDepKS

    properties (SetAccess = private)
        signalBuffer = [];
        robot
        pathToSoundFile
        samplingRate
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
            audiowrite(obj.pathToSoundFile, obj.signalBuffer, ...
                obj.samplingRate);
        end

        function [b, wait] = canExecute(obj)
            b = true;
            wait = false;
        end

        function execute(obj)
            if obj.firstCall
                obj.samplingRate = obj.blackboardSystem.dataConnect.afeFs;
                obj.firstCall = false;
            end
            
            blockSize = obj.blackboardSystem.dataConnect.timeStep;
            
            afeData = obj.getAFEdata();
            timeSig = afeData(1);
            earSignals = [timeSig{1}.getSignalBlock(blockSize, 0), ...
                timeSig{2}.getSignalBlock(blockSize, 0)];
            
            obj.signalBuffer = [obj.signalBuffer; earSignals];
        end
    end
end
