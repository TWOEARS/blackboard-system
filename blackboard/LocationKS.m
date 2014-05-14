classdef LocationKS < AbstractKS
    % LocationKS calculates posterior probabilities for each azimuth angle
    % and generates LocationHypothesis when provided with spatial 
    % observation
    
    properties (SetAccess = private)
        gmtkLoc;               % GMTK engine
        activeIndex = 0;       % The index of AcousticCues to be processed
        angles;                % All azimuth angles to be considered
        tempPath;              % A path for temporary files
    end
    
    methods
        function obj = LocationKS(blackboard, gmName, dimFeatures, angles)
            obj = obj@AbstractKS(blackboard);
            obj.gmtkLoc = gmtkEngine(gmName, dimFeatures);
            obj.angles = angles;
            obj.tempPath = fullfile(obj.gmtkLoc.workPath, 'flists');
            if ~exist(obj.tempPath, 'dir')
                mkdir(obj.tempPath);
            end
        end
        function setActiveArgument(obj, arg)
            obj.activeIndex = arg;
        end
        function b = canExecute(obj)
            b = false;
            if obj.activeIndex < 1
                numAcousticCues = obj.blackboard.getNumAcousticCues;
                for n=1:numAcousticCues
                    if obj.blackboard.acousticCues{n}.seenByLocationKS == false
                        obj.activeIndex = n;
                        b = true;
                        break
                    end
                end
            elseif obj.blackboard.acousticCues{obj.activeIndex}.seenByLocationKS == false
                b = true;
            end
        end
        function execute(obj)
            if obj.activeIndex < 1
                return
            end
            acousticCues = obj.blackboard.acousticCues{obj.activeIndex};
            if acousticCues.seenByLocationKS
                return
            end
            
            fprintf('-------- LocationKS has fired\n');
            
            % Generate a temporary feature flist for GMTK
            featureBlock = [acousticCues.itds; acousticCues.ilds];
            tempID = datestr(now,'yyyymmdd.HHMMSSFFF');
            fn = sprintf('%s/spatial_cues_%s', obj.tempPath, tempID);
            htkfn = strcat(fn, '.htk');
            writehtk(htkfn, featureBlock);
            flist = strcat(fn, '.flist');
            fidFlist = fopen(flist, 'w');
            fprintf(fidFlist, '%s\n', htkfn);
            fclose(fidFlist);

            % Calculate posteriors of clique 0 (which contains RV:location)
            obj.gmtkLoc.infer(flist, 0);

            % Delete the temporary flist
            delete(htkfn),
            delete(flist);
            
            % Now if successful, posteriors are written in output files 
            % with an appendix of _0 for the first utterance
            post = load(strcat(obj.gmtkLoc.outputCliqueFile, '_0'));
            
%             % Plot posteriors
%             hold off;
%             bar(obj.postDist);
%             set(gca,'XTickLabel', obj.angles, 'FontSize', 14);
%             xlabel('Azimuth (degrees)', 'FontSize', 16);
%             ylabel('Mean posteriors', 'FontSize', 16);
%             axis([0 length(obj.angles)+1 0 1]);
%             title(sprintf('Frame: %d, Head Orientation: %d degrees', feature.frame, obj.blackboard.headOrientation), 'FontSize', 16);
%             hold on;
%             plot([0 length(obj.angles)+1], [obj.postThreshold obj.postThreshold], 'r')
%             colormap(summer);

            % We simply take the average of posteriors across all the
            % samples for this block
            locHyp = LocationHypothesis(acousticCues.blockNo, acousticCues.headOrientation, obj.angles, mean(post,1));
            idx = obj.blackboard.addLocationHypothesis(locHyp);
            notify(obj.blackboard, 'NewLocationHypothesis', BlackboardEventData(idx));
            
            obj.activeIndex = 0;
            acousticCues.setSeenByLocationKS;
        end
    end
end
