classdef EmergencyDetectionKS < AbstractKS
    % EmergencyDetectionKS Checks for an emergency situation by evaluating
    %   the output of source identification.

    properties (SetAccess = private)
        accumulatedIdProbs = zeros(3, 1);
        smoothingFactor
        emergencyThreshold
        isEmergencyDetected = false;
    end
    
    properties (Access = private)
        firstCall = true;
    end

    methods
        function obj = EmergencyDetectionKS(varargin)
            obj = obj@AbstractKS();
            obj.invocationMaxFrequency_Hz = inf;
            
            defaultSmoothingFactor = 0.9;
            defaultEmergencyThreshold = 0.75;
            
            p = inputParser();
            p.addOptional('SmoothingFactor', defaultSmoothingFactor, ...
                @(x) validateattributes(x, {'numeric'}, {'scalar', ...
                'real', '>=', 0, '<=', 1}));
            p.addOptional('EmergencyThreshold', ...
                defaultEmergencyThreshold, @(x) validateattributes(x, ...
                {'numeric'}, {'scalar', 'real', '>', 0, '<', 1}));
            p.parse(varargin{:});
            
            obj.smoothingFactor = p.Results.SmoothingFactor;
            obj.emergencyThreshold = p.Results.EmergencyThreshold;            
        end

        function setEmergencyThreshold(obj, emergencyThreshold)
            obj.emergencyThreshold = emergencyThreshold;
        end
        
        function setSmoothingFactor(obj, smoothingFactor)
            obj.smoothingFactor = smoothingFactor;
        end

        function [bExecute, bWait] = canExecute(obj)
            sndTimeIdx = sort(cell2mat(keys(obj.blackboard.data)));
            bExecute = isfield(obj.blackboard.data(sndTimeIdx(end)), 'singleBlockObjectHypotheses');
            bWait = false;
        end

        function execute(obj)
            singleBlockObjHyp = obj.blackboard.getData('singleBlockObjectHypotheses', ...
                obj.trigger.tmIdx).data;
            
            numHyps = length(singleBlockObjHyp);
            
            for idx = 1 : numHyps
                hypLabel = singleBlockObjHyp(idx).label;
                
                switch hypLabel
                    case 'fire'
                        obj.accumulatedIdProbs(1) = ...
                            obj.smoothingFactor * obj.accumulatedIdProbs(1) + ...
                            (1 - obj.smoothingFactor) * singleBlockObjHyp(idx).p;
                    case 'alarm'
                        obj.accumulatedIdProbs(2) = ...
                            obj.smoothingFactor * obj.accumulatedIdProbs(2) + ...
                            (1 - obj.smoothingFactor) * singleBlockObjHyp(idx).p;
                    case 'baby'
                        obj.accumulatedIdProbs(3) = ...
                            obj.smoothingFactor * obj.accumulatedIdProbs(3) + ...
                            (1 - obj.smoothingFactor) * singleBlockObjHyp(idx).p;
                end
            end
            
            obj.accumulatedIdProbs(1) = ...
                obj.smoothingFactor * obj.accumulatedIdProbs(1);
            obj.accumulatedIdProbs(2) = ...
                obj.smoothingFactor * obj.accumulatedIdProbs(2);
            obj.accumulatedIdProbs(3) = ...
                obj.smoothingFactor * obj.accumulatedIdProbs(3);
            
            meanProb = mean(obj.accumulatedIdProbs);
            
            if meanProb >= obj.emergencyThreshold
                obj.isEmergencyDetected = true;
                disp('!!! EMERGENCY !!!');
            end
        end
    end
end
