classdef LocationKS < AuditoryFrontEndDepKS
    % LocationKS calculates posterior probabilities for each azimuth angle
    % and generates LocationHypothesis when provided with spatial 
    % observation
    
    properties (SetAccess = private)
        gmtkLoc;               % GMTK engine
        angles;                % All azimuth angles to be considered
        tempPath;              % A path for temporary files
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
            dimFeatures = param.nChannels * 2; % ITD + ILD
            obj.gmtkLoc = gmtkEngine(gmName, dimFeatures); %, '/Volumes/GMTK_ramdisk'
            angularResolution = 5; % determined by trained net.
            obj.angles = 0:angularResolution:(360-angularResolution);
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
    end
end
