classdef GenderRecognitionKS < AuditoryFrontEndDepKS
    % GENDERECOGNITIONKS Performs gender recognition (male/female).
    %
    % AUTHOR:
    %   Copyright (c) 2016      Christopher Schymura
    %                           Cognitive Signal Processing Group
    %                           Ruhr-Universitaet Bochum
    %                           Universitaetsstr. 150
    %                           44801 Bochum, Germany
    %                           E-Mail: christopher.schymura@rub.de
    %
    % LICENSE INFORMATION:
    %   This program is free software: you can redistribute it and/or
    %   modify it under the terms of the GNU General Public License as
    %   published by the Free Software Foundation, either version 3 of the
    %   License, or (at your option) any later version.
    %
    %   This material is distributed in the hope that it will be useful,
    %   but WITHOUT ANY WARRANTY; without even the implied warranty of
    %   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    %   GNU General Public License for more details.
    %
    %   You should have received a copy of the GNU General Public License
    %   along with this program. If not, see <http://www.gnu.org/licenses/>

    properties ( Access = private )
        basePath                % Path where extracted features and trained
                                % classifiers should be stored.
    end
    
    properties ( Constant, Hidden )
        BLOCK_SIZE_SEC = 0.5;   % This KS works with a constant block size
                                % of 500ms.
    end

    methods ( Access = public )
        function obj = GenderRecognitionKS()
            % GENDERECOGNITIONKS Method for class instantiation.
            %   Automaticlly handles classifier training if trained models
            %   are not available at instantiation. This KS is using a
            %   fixed set of parameters for feature extraction and
            %   classification, which cannot be changed by the user.
            
            % Generate AFE parameter structure. All parameters are fixed
            % and cannot be changed by the user.
            afeParameters = genParStruct( ...
                'pp_bNormalizeRMS', true, ...
                'ihc_method', 'halfwave', ...
                'fb_type', 'gammatone', ...
                'fb_lowFreqHz', 50, ...
                'fb_highFreqHz', 5000, ...
                'fb_nChannels', 32, ...
                'rm_wSizeSec', 0.02, ...
                'rm_hSizeSec', 0.01, ...
                'rm_wname', 'hann', ...
                'p_pitchRangeHz', [50, 600] );

            % Set AFE requests and instantiate AFE.
            requests{1}.name = 'ratemap';
            requests{1}.params = afeParameters;
            requests{2}.name = 'pitch';
            requests{2}.params = afeParameters;
            requests{3}.name = 'spectral_features';
            requests{3}.params = afeParameters;
            obj = obj@AuditoryFrontEndDepKS( requests );
            
            % Get path to stored features and models. If such a directory
            % does not exist, it will be created.
            obj.basePath = fullfile( xml.dbTmp, 'GenderRecognitionKS' );
            
            if ~exist( obj.basePath, 'dir' )
                mkdir( obj.basePath );
            end            
        end

        function [bExecute, bWait] = canExecute( obj )
            bExecute = obj.hasEnoughNewSignal( obj.BLOCK_SIZE_SEC );
            bWait = false;
        end

        function execute( obj )
            % Get features for current signal block.
            ratemap = obj.getNextSignalBlock( 1, ...
                obj.BLOCK_SIZE_SEC, obj.BLOCK_SIZE_SEC, false );
            pitch = obj.getNextSignalBlock( 2, ...
                obj.BLOCK_SIZE_SEC, obj.BLOCK_SIZE_SEC, false );
            spectralFeatures = obj.getNextSignalBlock( 3, ...
                obj.BLOCK_SIZE_SEC, obj.BLOCK_SIZE_SEC, false );            
        end
    end
end