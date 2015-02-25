classdef ColorationKS < AuditoryFrontEndDepKS
    % ColorationKS predicts the coloration of a signal compared ...

    properties (SetAccess = private)
        name;                  % Name of LocationKS
        gmtkLoc;               % GMTK engine
        angles;                % All azimuth angles to be considered
        tempPath;              % A path for temporary files
        dataPath = [xml.dbPath 'learned_models/locationKS/'];
        auditoryFrontEndParameter;
    end

    methods
        function obj = ColorationKS(gmName)
            blocksize_s = 0.5;
            param = genParStruct(...
                'fb_type', 'gammatone', ...
                'fb_lowFreqHz', 80, ...
                'fb_highFreqHz', 20000, ...
                'fb_nERBs', 1, ...
                'ihc_method', 'breebart', ...
                'adpt_model', 'adt_dau', ...
                'rm_decaySec', 0, ...
                'ild_wSizeSec', 20E-3, ...
                'ild_hSizeSec', 10E-3, ...
                'rm_wSizeSec', 20E-3, ...
                'rm_hSizeSec', 10E-3, ...
                'cc_wSizeSec', 20E-3, ...
                'cc_hSizeSec', 10E-3);
            requests.r{1} = 'adaptation';
            requests.p{1} = param;
            requests.r{2} = 'itd';
            requests.p{2} = param;
            requests.r{3} = 'time';
            requests.p{3} = param;
            obj = obj@AuditoryFrontEndDepKS( requests, blocksize_s );
            obj.name = gmName;
            obj.auditoryFrontEndParameter = param;
            dimFeatures = param.fb_nChannels * 2; % ITD + ILD
            obj.gmtkLoc = gmtkEngine(gmName, dimFeatures, obj.dataPath);
            obj.angles = 0:obj.angularResolution:(360-obj.angularResolution);
            obj.tempPath = fullfile(obj.gmtkLoc.workPath, 'tempdata');
            if ~exist(obj.tempPath, 'dir')
                mkdir(obj.tempPath);
            end
            obj.invocationMaxFrequency_Hz = 2;
        end

        function [bExecute, bWait] = canExecute(obj)
            signal = obj.getAuditoryFrontEndRequest(3); % get time signal
            bExecute = hasSignalEnergy(signal);
            bWait = false;
        end

        function execute(obj)
            ildsSObj = obj.getAuditoryFrontEndRequest(1);
            ilds = ildsSObj.getSignalBlock( obj.blocksize_s, obj.timeSinceTrigger )';
            itdsSObj = obj.getAuditoryFrontEndRequest(2);
            itds = itdsSObj.getSignalBlock( obj.blocksize_s, obj.timeSinceTrigger )' .* 1000;

            % Generate a temporary feature flist for GMTK
            featureBlock = [itds; ilds];
            if sum(sum( isnan( featureBlock ) + isinf( featureBlock ) )) > 0
                warning( 'LocKS: NaNs or Infs in feature block; aborting inference' );
                return;
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
            currentHeadOrientation = obj.blackboard.getLastData( 'headOrientation' ).data;
            locHyp = LocationHypothesis(currentHeadOrientation, obj.angles, mean(post,1));
            obj.blackboard.addData( 'locationHypotheses', locHyp, false, obj.trigger.tmIdx );
            notify( obj, 'KsFiredEvent', BlackboardEventData( obj.trigger.tmIdx ) );
        end

        function obj = generateTrainingData(obj)
            %generateTrainingData(obj) extracts ITDs and ILDs from using HRTF and the grid
            %speech corpus. This data can then be used to train the GMTK localisation
            %model
            
            % Start simulator with corresponding localisation scene
            sim = simulator.SimulatorConvexRoom(['learned_models/locationKS/' ...
                                                 obj.name '.xml'], true);
            % Create data path
            mkdir(obj.dataPath,obj.name);
            mkdir([obj.dataPath filesep obj.name],'data');
            dataFilesPath = [obj.dataPath filesep obj.name filesep 'data'];
            % Read training data
            trainSignal = readAudioFiles(['sound_databases/grid_subset/' ...
                                          'training/training.wav'], ...
                                         'Length', 5*44100);
            % Generate binaural cues
            obj.angles = 0:obj.angularResolution:(360-obj.angularResolution);
            for n = 1:length(obj.angles)
                fprintf('----- Calculating ITDs and ILDs at %.1f degrees\n', ...
                        obj.angles(n));
                sim.Sources{1}.set('Azimuth', obj.angles(n));
                sim.ReInit = true;
                sim.Sources{1}.setData(trainSignal);
                sig = sim.getSignal(5*44100);
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

% vim: set sw=4 ts=4 et tw=90:
