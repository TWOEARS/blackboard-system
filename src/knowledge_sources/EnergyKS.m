classdef EnergyKS < Wp2DepKS
    % This is a more than basic implementation of a signal activity 
    % detector. The algorithm is not based on perception.
    % TODO: use reasonabale algorithm.
    
    properties (SetAccess = private)
    end

    methods
        function obj = EnergyKS( blackboard, blockSize_s )
            wp2requests.r{1} = 'time';
            wp2requests.p{1} = '';
            obj = obj@Wp2DepKS( blackboard, wp2requests, blockSize_s );
            obj.invocationMaxFrequency_Hz = 10;
       end
        
        function b = canExecute( obj )
            b = true;
        end
        
        function execute( obj )
            if obj.blackboard.verbosity > 0
                fprintf('-------- EnergyKS has fired.\n');
            end
            
            signal = obj.getReqSignal( 1 );
            lEnergy = std( ...
                signal{1}.getSignalBlock( obj.blocksize_s, obj.timeSinceTrigger )...
                );
            rEnergy = std( ...
                signal{2}.getSignalBlock( obj.blocksize_s, obj.timeSinceTrigger )...
                );
            
            if lEnergy + rEnergy >= 0.01
                notify( obj, 'KsFiredEvent', BlackboardEventData( obj.trigger.tmIdx ) );
            end
        end
    end
end
