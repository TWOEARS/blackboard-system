classdef IdentityLocationKS < IdentityKS
    
    properties (SetAccess = private)
        classnames;
        azimuths;
    end

    methods
        function obj = IdentityLocationKS( modelName, modelDir )
            obj = obj@IdentityKS( modelName, modelDir );
            modelFileName = fullfile(modelDir, modelName);
            v = load( [modelFileName '.model.mat'] );
            obj.classnames = v.classnames;
            obj.azimuths = v.azimuths;
            obj.model.initNet(v.modelDir, v.fname_net_def, v.fname_weights);
        end
        
        function execute( obj )
            afeData = obj.getAFEdata();
            afeData = obj.blockCreator.cutDataBlock( afeData, obj.timeSinceTrigger );
            
            obj.featureCreator.setAfeData( afeData );
            x = obj.featureCreator.constructVector();
            
            [blobs_in, blobs_in_names] = obj.reshape2Blob( x{1}, x{2} );
            [d, score] = obj.model.applyModel( {blobs_in, blobs_in_names} );
            
            blobs_out_names = fieldnames(score);
            score_blob = score.(blobs_out_names{1}); % use only first one
            d_blob = d.(blobs_out_names{1}); % use only first one
            currentHeadOrientation = obj.blackboard.getLastData('headOrientation').data;
            for ii = 1:numel(obj.classnames)
                % invert void bin output
                id_prob =  1-score_blob(end, ii);
                id_decision =  1-d_blob(end, ii);
                loc_probs =  score_blob(1:end-1, ii);
                loc_decisions =  d_blob(1:end-1, ii);
                bbprintf(obj, '[IdentityLocationKS:] %s with %i%% probability.\n', ...
                         obj.classnames{ii}, int16(id_prob*100));
                hyp = IdentityLocationHypothesis( obj.classnames{ii}, ...
                    id_prob, id_decision, obj.blockCreator.blockSize_s, ...
                    currentHeadOrientation, ...
                    obj.azimuths, loc_probs, loc_decisions );
                obj.blackboard.addData( 'identityHypotheses', hyp, true, obj.trigger.tmIdx );
                notify( obj, 'KsFiredEvent', BlackboardEventData( obj.trigger.tmIdx ) );
            end % classnames
        end
    end
    
    methods (Access = protected)        
        function [x_feat, feature_type_names] = reshape2Blob(obj, x, featureNames)
            % twoears2Blob  reshape feature and ground truth vectors into 4-D Blob for caffe
            %   For the feature vector x it expects a shape of (N x D)
            %   where N is the number of samples and D is the total no. of features
            %
            %   For the ground truth vectors y it expects a shape of (N x K)
            %   where N is the number of samples and K is the number of classes.
            %   The ground truth vectors can be one-hot or multi-label vectors
            %
            x = x';

            % assume first field contains feature name
            feature_type_names = unique( cellfun(@(v) v(1), featureNames(1,:)) );
            x_feat = cell( size(feature_type_names) );
            for ii = 1 : numel(feature_type_names)
                % Determine time bins in a single block.
                % We assume the block size is constant within a feature type
                is_feat = cellfun(@(v) strfind([v{:}], feature_type_names{ii}), ...
                    featureNames, 'un', false);
                feat_idxs = find(not(cellfun('isempty', is_feat)));

                t_idxs_names = unique(cellfun(@(v) v(4), featureNames(feat_idxs)));
                t_idxs = sort( cell2mat( cellfun(@(x) str2double(char(x(2:end))), ...
                    t_idxs_names, 'un', false) ) );
                num_blocks = length( t_idxs );
                
                if strcmp(feature_type_names{ii}, 'amsFeatures')
                    % T x F x mF x N
                    num_freqChannels = obj.featureCreator.amFreqChannels;
                    num_mod = obj.featureCreator.amChannels;
                elseif strcmp(feature_type_names{ii}, 'ratemap')
                    %  T x F x 1 x N
                    num_freqChannels = obj.featureCreator.freqChannels;
                    num_mod = 1;
                elseif strcmp(feature_type_names{ii}, 'crosscorrelation')
                    %  T x F x nLags x N
                    num_freqChannels = obj.featureCreator.freqChannels;
                    num_mod = 99;
                elseif strcmp(feature_type_names{ii}, 'ild')
                    %  T x F x 1 x N
                    num_freqChannels = obj.featureCreator.freqChannels;
                    num_mod = 1;
                else
                    warning('Skipping unsupported feature type %s.', feature_type_names{ii});
                end

                % concatenate binaural features into last (modulation dim)
                feat_binaural_idxs = find( BindingKS.isBinaural(featureNames(feat_idxs)) );
                if isequal(length(feat_binaural_idxs), length(featureNames(feat_idxs)) )
                    disp('binaural feature');
                    num_mod = num_mod * 2;
                end
                x_feat{ii} = reshape( x(feat_idxs, :), ...
                    num_blocks, num_freqChannels, num_mod, ...
                    size( x, 2 ) );
            end % format features
        end
    end
    
    methods (Static)
        function [is_binaural] = isBinaural(featureNames)
            % isBinaural  identify binaural features

            is_not_combined = cellfun(@(v) strfind([v{:}], 'LRmean'), featureNames, ...
                'un', false);
            is_not_combined = cellfun('isempty', is_not_combined);
            is_not_mono = cellfun(@(v) strfind([v{:}], 'mono'), featureNames, 'un', false);
            is_not_mono = cellfun('isempty', is_not_mono);
            is_binaural = is_not_mono & is_not_combined;
        end
    end
end
