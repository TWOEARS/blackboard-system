classdef SegmentationKS < AuditoryFrontEndDepKS
    % SEGMENTATIONKS This knowledge source computes soft or binary masks
    %   from a set of auditory features in the time frequency domain. The
    %   number of sound sources that should be segregated must be specified
    %   upon initialization. Each mask is associated with a corresponding
    %   estimate of the source position, given as Gaussian distributions.

    properties (SetAccess = private)

    end

    methods (Access = public)
        function obj = SegmentationKS()
            
        end

        function delete(obj)

        end

        function [bExecute, bWait] = canExecute(obj)

        end

        function execute(obj)
           
        end

        function obj = generateTrainingData(obj, sceneDescription)
          
        end

        function obj = removeTrainingData(obj)
          
        end

        function obj = train(obj)
          
        end
    end
end