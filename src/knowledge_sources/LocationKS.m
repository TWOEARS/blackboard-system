classdef LocationKS < AuditoryFrontEndDepKS
    % LocationKS calculates posterior probabilities for each azimuth angle
    % and generates LocationHypothesis when provided with spatial 
    % observation
    
    properties (SetAccess = private)
        name;                  % Name of LocationKS
        gmtkLoc;               % GMTK engine
        angles;                % All azimuth angles to be considered
        tempPath;              % A path for temporary files
        dataPath = [xml.dbPath 'learned_models/locationKS/'];
        angularResolution = 1;
        auditoryFrontEndParameter;
    end
    
    methods
        function obj = LocationKS(gmName)
            blocksize_s = 0.5;
            param = genParStruct('f_low',80,'f_high',8000,...
                'nChannels',32,...
                'rm_decaySec',0,...
                'ild_wSizeSec',20E-3,...
                'ild_hSizeSec',10E-3,'rm_wSizeSec',20E-3,...
                'rm_hSizeSec',10E-3,'cc_wSizeSec',20E-3,...
                'cc_hSizeSec',10E-3);
            requests.r{1} = 'ild';
            requests.p{1} = param;
            requests.r{2} = 'itd_xcorr';
            requests.p{2} = param;
            requests.r{3} = 'time';
            requests.p{3} = param;
            obj = obj@AuditoryFrontEndDepKS( requests, blocksize_s );
            obj.name = gmName;
            obj.auditoryFrontEndParameter = param;
            dimFeatures = param.nChannels * 2; % ITD + ILD
            obj.gmtkLoc = gmtkEngine(gmName, dimFeatures, obj.dataPath);
            obj.angles = 0:obj.angularResolution:(360-obj.angularResolution);
            obj.tempPath = fullfile(obj.gmtkLoc.workPath, 'tempdata');
            if ~exist(obj.tempPath, 'dir')
                mkdir(obj.tempPath);
            end
            obj.invocationMaxFrequency_Hz = 2;
        end
        
        function [b, wait] = canExecute(obj)
            signal = obj.getReqSignal( 3 );
            lEnergy = std( ...
                signal{1}.getSignalBlock( obj.blocksize_s, obj.timeSinceTrigger )...
                );
            rEnergy = std( ...
                signal{2}.getSignalBlock( obj.blocksize_s, obj.timeSinceTrigger )...
                );
            
            b = (lEnergy + rEnergy >= 0.01);
            wait = false;
        end
        
        function execute(obj)
            ildsSObj = obj.getReqSignal( 1 );
            ilds = ildsSObj.getSignalBlock( obj.blocksize_s, obj.timeSinceTrigger )';
            itdsSObj = obj.getReqSignal( 2 );
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
            % Generate data for training of the model
            sim = simulator.SimulatorConvexRoom(['learned_models/locationKS/' ...
                                                 obj.name '.xml'], true);
            % Create data path
            mkdir(obj.dataPath,obj.name);
            % Read training data
            trainSignal = readAudioFiles(['sound_databases/grid_subset/' ...
                                          'training/training.wav'], ...
                                         'Length', 5*44100);
            % Generate binaural cues
            obj.angles = 0:obj.angularResolution:(360-obj.angularResolution);
            for n = 1:length(obj.angles)
                fprintf('----- Calculating ITDs and ILDs at %.1f degrees\n', ...
                        obj.angles(n));
                %sim.Sources{1}.Azimuth = obj.angles(n);
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
                itd = data.itd_xcorr{1}.Data' .* 1000; % convert to ms
                ild = data.ild{1}.Data';
                fileName = fullfile(dataPath, ...
                                    sprintf('spatial_cues_angle%05.1f', angles(n)));
                writehtk(strcat(fileName, '.htk'), [itd; ild]);
                fprintf('\n');
            end
            sim.ShutDown = true;
        end
    end
end

% vim: set sw=4 ts=4 et tw=90:
