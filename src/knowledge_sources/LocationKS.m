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
            obj.gmtkLoc = gmtkEngine(gmName, dimFeatures, '/Volumes/GMTK_ramdisk');
            obj.angles = angles;
            obj.tempPath = fullfile(obj.gmtkLoc.workPath, 'tempdata');
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
            
            if obj.blackboard.verbosity > 0
                fprintf('-------- LocationKS has fired\n');
            end
            
            % Generate a temporary feature flist for GMTK
            featureBlock = [acousticCues.itds; acousticCues.ilds];
            [~,tmpfn] = fileparts(tempname);
            tmpfn = fullfile(obj.tempPath, tmpfn);
            htkfn = strcat(tmpfn, '.htk');
            writehtk(htkfn, featureBlock);
            flist = strcat(tmpfn, '.flist');
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
            
            %bar(obj.angles, mean(post,1))
            %bar(mod(obj.angles+headRotation,360), mean(post,1));
            
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
