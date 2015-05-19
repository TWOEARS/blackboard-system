classdef LocationKS < AuditoryFrontEndDepKS
    % LocationKS calculates posterior probabilities for each azimuth angle
    % and generates LocationHypothesis when provided with spatial 
    % observation

    properties (SetAccess = private)
        name;                  % Name of LocationKS
        gmtkLoc;               % GMTK engine
        angles;                % All azimuth angles to be considered
        tempPath;              % A path for temporary files
        dataPath = [xml.dbPath 'learned_models' filesep 'LocationKS' filesep];
        angularResolution = 1; % Default angular resolution is 1deg
        auditoryFrontEndParameter;
    end

    methods
        function obj = LocationKS(gmName, angularResolution)
            blocksize_s = 0.5;
            param = genParStruct(...
                'fb_type', 'gammatone', ...
                'fb_lowFreqHz', 80, ...
                'fb_highFreqHz', 8000, ...
                'fb_nChannels', 32, ...
                'rm_decaySec', 0, ...
                'ild_wSizeSec', 20E-3, ...
                'ild_hSizeSec', 10E-3, ...
                'rm_wSizeSec', 20E-3, ...
                'rm_hSizeSec', 10E-3, ...
                'cc_wSizeSec', 20E-3, ...
                'cc_hSizeSec', 10E-3);
            requests.r{1} = 'ild';
            requests.p{1} = param;
            requests.r{2} = 'itd';
            requests.p{2} = param;
            requests.r{3} = 'time';
            requests.p{3} = param;
            requests.r{4} = 'ic';
            requests.p{4} = param;
            obj = obj@AuditoryFrontEndDepKS(requests, blocksize_s);
            obj.auditoryFrontEndParameter = param;
            obj.name = gmName;
            if nargin>1
                obj.angularResolution = angularResolution;
            end
            dimFeatures = param.fb_nChannels * 2; % ITD + ILD
            obj.gmtkLoc = gmtkEngine(gmName, dimFeatures, obj.dataPath);
            obj.angles = 0:obj.angularResolution:(360-obj.angularResolution);
            obj.tempPath = obj.gmtkLoc.tempPath;
            obj.invocationMaxFrequency_Hz = 2;
        end
        
        function delete(obj)
            disp( 'LocationKS delete' );
        end

        function [bExecute, bWait] = canExecute(obj)
            signal = obj.getAuditoryFrontEndRequest(3); % time signal
            bExecute = obj.hasSignalEnergy(signal);
            bWait = false;
        end

        function execute(obj)
            ildsSObj = obj.getAuditoryFrontEndRequest(1);
            ilds = ildsSObj.getSignalBlock(obj.blocksize_s, obj.timeSinceTrigger)';
            itdsSObj = obj.getAuditoryFrontEndRequest(2);
            itds = itdsSObj.getSignalBlock(obj.blocksize_s, obj.timeSinceTrigger)' .* ...
                1000;
            icsSObj = obj.getAuditoryFrontEndRequest(4);
            ics = icsSObj.getSignalBlock(obj.blocksize_s, obj.timeSinceTrigger)';

            % Check if the trained data has the correct angular resolution
            % The angular resolution of the trained data can be found in the corresponding
            % *.str file. We first extract it from that file and compare it then to the
            % angular resolution of the running LocationKS
            strFile = fullfile(obj.gmtkLoc.workPath, strcat(obj.name, '.str'));
            fid = fopen(strFile,'r');
            strText = fscanf(fid,'%s');
            fclose(fid);
            % Find the position of the stored angular resolution and return number of
            % stored angular values
            nAngles = str2double(regexpi(strText, ...
                'discretehiddencardinality([0-9]+);', 'tokens', 'once'));
            trainedAngularResolution = 360/nAngles;
            if trainedAngularResolution~=obj.angularResolution
                error(['Your current angular resolution (%.1f) mismatches the ', ...
                       'learned resolution (%.1f).'], obj.angularResolution, ...
                       trainedAngularResolution);
            end

            % Generate a temporary feature flist for GMTK
            featureBlock = [itds; ilds];
            if sum(sum(isnan(featureBlock) + isinf(featureBlock))) > 0
                warning('LocationKS: NaNs or Infs in feature block; aborting inference');
                return;
            end
            % FIXME: the following is a workaround, as the tmp dir is deleted at the
            % moment after every execution of LocationKS, but only created once at the
            % instanciation of the gmtkEngine. In the long run it should only
            % be deleted at the end of the Blackboard execution, when the agenda of the
            % Blackboard is empty.
            if ~exist(obj.tempPath, 'dir')
                mkdir(obj.tempPath);
            end
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

            % Now if successful, posteriors are written in output files 
            % with an appendix of _0 for the first utterance
            post = load(strcat(obj.gmtkLoc.outputCliqueFile, '_0'));

            % We simply take the average of posteriors across all the
            % samples for this block
            currentHeadOrientation = obj.blackboard.getLastData('headOrientation').data;
            locHyp = LocationHypothesis(currentHeadOrientation, obj.angles, mean(post,1));
            obj.blackboard.addData('locationHypotheses', ...
                locHyp, false, obj.trigger.tmIdx);
            notify(obj, 'KsFiredEvent', BlackboardEventData( obj.trigger.tmIdx ));

            % Delete the all temporary data
            delete(htkfn);
            delete(flist);
            delete(fullfile(obj.tempPath, strcat(obj.name, '.post')));
            delete(fullfile(obj.tempPath, strcat(obj.name, '.post_0')));
            delete(fullfile(obj.tempPath, 'jtcommand'));
            % FIXME: we cannot remove the temp dir at this position, because execute()
            % will be called several times and the tempdir is needed, but only initialized
            % at the creation time of LocationKS(). Is there a way to shutdown the KS at
            % the end of the Blackboard session and remove the tempdir then?
            % See also the FIXME entry above
            % TODO: put into deconstructor.
            rmdir(obj.tempPath);
        end

        function cleanup(obj)
            % Clean up after the last execution of the KS and remove temporary directory
            rmdir(obj.tempPath);
        end

        function obj = generateTrainingData(obj)
            %generateTrainingData(obj) extracts ITDs and ILDs from using HRTF and the grid
            %speech corpus. This data can then be used to train the GMTK localisation
            %model

            % Start simulator with corresponding localisation scene
            sim = simulator.SimulatorConvexRoom(['learned_models/LocationKS/' ...
                                                 obj.name '.xml'], true);
            % Create data path
            mkdir(obj.dataPath,obj.name);
            mkdir([obj.dataPath filesep obj.name],'data');
            dataFilesPath = [obj.dataPath filesep obj.name filesep 'data'];
            % Read training data
            trainSignal = normalise(randn(10*sim.SampleRate,1));
            %trainSignal = readAudioFiles(['sound_databases/grid_subset/' ...
            %                              'training/training.wav'], ...
            %                             'Length', 5*44100);
            % Generate binaural cues
            obj.angles = 0:obj.angularResolution:(360-obj.angularResolution);
            for n = 1:length(obj.angles)
                fprintf('----- Calculating ITDs and ILDs at %.1f degrees\n', ...
                        obj.angles(n));
                sim.Sources{1}.set('Azimuth', obj.angles(n));
                sim.ReInit = true;
                sim.Sources{1}.setData(trainSignal);
                sig = sim.getSignal(10*sim.SampleRate);
                % Compute binaural cues using the Auditory Front End
                data = dataObject(sig, sim.SampleRate);
                auditoryFrontEnd = manager(data, obj.requests.r, ...
                                           obj.auditoryFrontEndParameter);
                auditoryFrontEnd.processSignal();
                % Save binaural cues
                itd = data.itd{1}.Data(:)' .* 1000; % convert to ms
                ild = data.ild{1}.Data(:)';
                fileName = fullfile(dataFilesPath, ...
                                    sprintf('spatial_cues_angle%05.1f', obj.angles(n)));
                writehtk(strcat(fileName, '.htk'), [itd; ild]);
                fprintf('\n');
            end
            sim.ShutDown = true;
        end

        function obj = removeTrainingData(obj)
            %removeTrainingData(obj) deletes all the data that was locally created by
            %generateTrainingData(obj).
            if exist(fullfile(obj.gmtkLoc.workPath, 'data'),'dir')
                rmdir(fullfile(obj.gmtkLoc.workPath, 'data'), 's');
            end
            if exist(fullfile(obj.gmtkLoc.workPath, 'flists'),'dir')
                rmdir(fullfile(obj.gmtkLoc.workPath, 'flists'), 's');
            end
            delete(fullfile(obj.gmtkLoc.workPath, '*command'));
            delete(fullfile(obj.gmtkLoc.workPath, '*_train*'));
            delete(fullfile(obj.gmtkLoc.workPath, '*0.gmp'));
            delete(fullfile(obj.gmtkLoc.workPath, '*1.gmp'));
            delete(fullfile(obj.gmtkLoc.workPath, '*2.gmp'));
        end

        function obj = train(obj)
            %train(obj) trains the locationKS using extracted ITDs and ILDs which are
            %stored in the Two!Ears database under learned_models/locationKS/ and GMTK

            % Configuration
            featureExt = 'htk';
            labelExt = 'lab';

            % Generate GMTK parameters
            % Now need to create GM structure files (.str) and generate relevant GMTK
            % parameters, either manually or with generateGMTKParameters.
            % Finally, perform model triangulation.
            generateGmtkParameters(obj.gmtkLoc, numel(obj.angles));
            obj.gmtkLoc.triangulate;
            % Estimate GM parameters
            flistPath = fullfile(obj.gmtkLoc.workPath, 'flists');
            if ~exist(flistPath, 'dir')
                mkdir(flistPath);
            end
            trainFeatureList = fullfile(flistPath, 'train_features.flist');
            trainLabelList = fullfile(flistPath, 'train_labels.flist');
            fidObsList = fopen(trainFeatureList, 'w');
            fidLabList = fopen(trainLabelList, 'w');
            for n = 1:numel(obj.angles)
                baseFileName = fullfile(obj.dataPath, obj.name, 'data', ...
                      sprintf('spatial_cues_angle%05.1f', obj.angles(n)));
                featureFileName = sprintf('%s.%s', baseFileName, featureExt);
                fprintf(fidObsList, '%s\n', featureFileName);
                labelFileName = sprintf('%s.%s', baseFileName, labelExt);
                fprintf(fidLabList, '%s\n', labelFileName);
                % Generate and save feature labels for each angle
                ftr = readhtk(featureFileName);
                fid = fopen(labelFileName, 'w');
                fprintf(fid, '%d\n', repmat(n-1,1,size(ftr,2)));
                fclose(fid);
            end
            fclose(fidObsList);
            fclose(fidLabList);
            obj.gmtkLoc.train(trainFeatureList, trainLabelList);
        end
    end
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
