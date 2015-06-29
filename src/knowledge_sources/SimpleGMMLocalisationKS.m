classdef SimpleGMMLocalisationKS < AbstractKS
    % SimpleGMMLocalisationKS localises the source using GMMs with the MAP
    % criterion

    properties (SetAccess = private)
        gmtkLoc;               % GMTK engine
        activeIndex = 0;       % The index of AcousticCues to be processed
        angles;                % All azimuth angles to be considered
        tempPath;              % A path for temporary files
    end

    methods
        function obj = SimpleGMMLocalisationKS(blackboard, gmName, ...
                                               dimFeatures, angles)
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

            if obj.blackboard.verbosity > 0
                fprintf('-------- SimpleGMMLocalisationKS has fired\n');
            end

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

            % We simply take the average of posteriors across all the
            % samples for this block
            meanPost = mean(post,1);
            [m,locIdx] = max(meanPost);
            ploc = PerceivedLocation(acousticCues.blockNo, ...
                acousticCues.headOrientation, obj.angles(locIdx), m);
            idx = obj.blackboard.addPerceivedLocation(ploc);
            notify(obj.blackboard, 'NewPerceivedLocation', ...
                BlackboardEventData(idx));
            % Now it's ready for the next block
            obj.blackboard.setReadyForNextBlock(true);

            obj.activeIndex = 0;
            acousticCues.setSeenByLocationKS;
        end
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
