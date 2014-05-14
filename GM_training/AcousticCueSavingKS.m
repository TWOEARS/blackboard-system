classdef AcousticCueSavingKS < AbstractKS
    % LocationKS calculates posterior probabilities for each azimuth angle
    % and generates LocationHypothesis when provided with spatial 
    % observation
    
    properties (SetAccess = private)
        activeIndex = 0;       % The index of SpatialFeature to be processed
        dataPath;              % A path for saving feature files
        label;                 % Label of the features being generated
    end
    
    methods
        function obj = AcousticCueSavingKS(blackboard, dataPath, label)
            obj = obj@AbstractKS(blackboard);
            obj.dataPath = dataPath;
            obj.label = label;
        end
        function setActiveArgument(obj, arg)
            obj.activeIndex = arg;
        end
        function b = canExecute(obj)
            b = false;
            if obj.activeIndex < 1
                numSpatialCues = obj.blackboard.getNumSpatialCues;
                for n=1:numSpatialCues
                    if obj.blackboard.spatialCues{n}.seenByLocationKS == false
                        obj.activeIndex = n;
                        b = true;
                        break
                    end
                end
            elseif obj.blackboard.spatialCues{obj.activeIndex}.seenByLocationKS == false
                b = true;
            end
        end
        function execute(obj)
            if obj.activeIndex < 1
                return
            end
            spatialCues = obj.blackboard.spatialCues{obj.activeIndex};
            if spatialCues.seenByLocationKS
                return
            end
            
            fprintf('-------- AcousticCueSavingKS has fired\n');
            
            % Add spatial cues to the feature array
            featureBlock = [spatialCues.itds; spatialCues.ilds];
            fprintf('Saving spatial data for block %d\n', spatialCues.blockNo);
            fn = fullfile(obj.dataPath, sprintf('%s_location%d_block%d', 'spatial_cues', obj.label, spatialCues.blockNo));
            writehtk(strcat(fn, '.htk'), featureBlock);

            % Label for each frame
            fid = fopen(strcat(fn, '.lab'), 'w');
            fprintf(fid, '%d\n', repmat(obj.label,1,size(featureBlock,2)));
            fclose(fid);

            obj.activeIndex = 0;
            spatialCues.setSeenByLocationKS;
            obj.blackboard.setReadyForNextBlock(true);
        end
    end
end
