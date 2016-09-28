classdef StreamSegregationKS < AuditoryFrontEndDepKS
    %STREAMSEGREGATIONKS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties ( SetAccess = private )
        observationModel
        blockSize
        useFixedAzimuths = false;
        fixedAzimuths = [];
    end
    
    methods ( Access = public )
        function obj = StreamSegregationKS( parameterFile, varargin )
            % STREAMSEGREGATIONKS
            
            % Check input arguments.
            p = inputParser();
            defaultBlockSize = 0.5;
            
            p.addRequired( 'ParameterFile', @(x) exist(x, 'file') );
            p.addOptional( 'BlockSize', defaultBlockSize, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'scalar', 'real', 'positive'}) );
            p.addOptional( 'FixedAzms', [] );
            
            if nargin == 1
                p.parse( parameterFile );
            else
                p.parse( parameterFile, varargin{:} );
            end
            
            % Read training parameters and load corresponding observation
            % model.
            trainingParameters = ReadYaml( p.Results.ParameterFile );
            
            % Get AFE parameters and initialize AFE
            [~, ~, afeRequests, afeParameters] = ...
                tools.setupAuditoryFrontend( trainingParameters );
            numRequests = length( afeRequests );
            
            requests = cell( 1, numRequests );            
            for requestIdx = 1 : numRequests
                requests{requestIdx}.name = afeRequests{requestIdx};
                requests{requestIdx}.params = afeParameters;
            end
            obj = obj@AuditoryFrontEndDepKS( requests );
            
            % If fixed azimuth angles should be used, this has to be
            % specified as additional input arguments, where each input
            % represents an azimuth angle in degrees.
            if ~isempty( p.Results.FixedAzms )
                obj.useFixedAzimuths = true;
                obj.fixedAzimuths = p.Results.FixedAzms;
            end
            
            % Assign block size.
            obj.blockSize = p.Results.BlockSize;
            
            % Load observation model for the specified set of parameters.
            obj.observationModel = ObservationModel( trainingParameters );
        end
        
        function setFixedAzimuths( obj, newFixedAzimuths )
            obj.fixedAzimuths = newFixedAzimuths;
            obj.useFixedAzimuths = ~isempty( newFixedAzimuths );
        end
        
        function setBlocksize( obj, newBlocksize )
            obj.blockSize = newBlocksize;
        end
        
        function [bExecute, bWait] = canExecute(obj)
            bExecute = obj.hasEnoughNewSignal( obj.blockSize );
            bWait = false;
        end
        
        function execute(obj)
            % Get binaural features.
            itds = obj.getNextSignalBlock( 1, obj.blockSize, ...
                obj.blockSize, false );
            ilds = obj.getNextSignalBlock( 2, obj.blockSize, ...
                obj.blockSize, false );
            
            % Get current look direction.
            lookDirection = obj.blackboard.getLastData( 'headOrientation' );
            lookDirection = lookDirection.data;
            
            % Check if azimuth angles are fixed and compute soft-masks.
            if obj.useFixedAzimuths
                numAzimuths = length( obj.fixedAzimuths );
                likelihoods = zeros( size(itds, 1), size(itds, 2), numAzimuths );
                refAzm = zeros( size( obj.fixedAzimuths ) );
                
                for azimuthIdx = 1 : numAzimuths
                    % Get relative azimuths -- obj.fixedAzimuths thus contains absolute
                    % azimuths
                    headRelativeAzimuth = wrapTo180( obj.fixedAzimuths(azimuthIdx) - ...
                        lookDirection );
                    refAzm(azimuthIdx) = headRelativeAzimuth;
                    
                    likelihoods(:, :, azimuthIdx) = ...
                        obj.observationModel.computeLikelihood( ...
                        itds, ilds, headRelativeAzimuth / 180 * pi );
                end
            else
                % TODO: Add interface to DnnLocalsationKS here...
            end
            
            % Normalize likelihoods and put hypotheses on the blackboard.
            likelihoodSum = squeeze( sum(permute(likelihoods, [3 2 1]),1) )';
            likelihoodSum(likelihoodSum == 0) = 1; % do not divide by 0
            softMasks = bsxfun( @rdivide, likelihoods, likelihoodSum );
            numSoftMasks = size( softMasks, 3 );
            
            afeData = obj.getAFEdata();
            cfHz = afeData(2).cfHz;
            hopSize = 1 / afeData(2).FsHz;

            for hypIdx = 1 : numSoftMasks
                % Add segmentation hypothesis to the blackboard
                segHyp = SegmentationHypothesis( ['Source ', num2str(hypIdx)], ...
                    'SoundSource', squeeze(softMasks(:, :, hypIdx)), ...
                    cfHz, hopSize, refAzm(hypIdx) );
                obj.blackboard.addData('segmentationHypotheses', ...
                    segHyp, true, obj.trigger.tmIdx);
            end
        end
    end    
end