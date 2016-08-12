classdef StreamSegregationKS < AuditoryFrontEndDepKS
    %STREAMSEGREGATIONKS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties ( SetAccess = private )
        observationModel
        blockSize
        dataPath = fullfile('learned_models', 'StreamSegregationKS');
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
            
            if nargin == 1
                p.parse( parameterFile );
            else
                p.parse( parameterFile, varargin{1} );
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
            obj = obj@AuditoryFrontEndDepKS(requests);
            
            % If fixed azimuth angles should be used, this has to be
            % specified as additional input arguments, where each input
            % represents an azimuth angle in degrees.
            if nargin > 2
                obj.useFixedAzimuths = true;
                obj.fixedAzimuths = cell2mat( varargin(2 : end) );
            end
            
            % Assign block size.
            obj.blockSize = p.Results.BlockSize;
            
            % Load observation model for the specified set of parameters.
            obj.observationModel = ObservationModel( trainingParameters );
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
            
            % Check if azimuth angles are fixed and compute soft-masks.
            if obj.useFixedAzimuths
                for azimuth = obj.fixedAzimuths
                    likelihood = ...
                        obj.observationModel.computeLikelihood( itds, ilds, 0 );
                end
            else
                
            end
        end
    end    
end