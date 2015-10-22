classdef VonMisesMixture
    % VONMISESMIXTURE This class can be used to model a mixture of von
    %   Mises distributions. It provides functions to estimate the
    %   distribution parameters, compute likelihoods for given observations
    %   and draw samples from the distribution. Furthermore, it can be used
    %   for clustering applications involving circular data. Please refer
    %   to the individual function headers for further details.
    %
    % AUTHORS:
    %   Christopher Schymura (christopher.schymura@rub.de)
    %   Cognitive Signal Processing Group
    %   Ruhr-Universitaet Bochum
    %   Universitaetsstr. 150, 44801 Bochum    
    
    properties (GetAccess = public, SetAccess = protected)
        nComponents             % Number of mixture components.
        mu                      % Kx1 vector, containing the circular means
                                % of all k components of the mixture 
                                % distribution. The range of each element
                                % is bounded in [-pi, pi].
        kappa                   % Kx1 vector, containing the concentration
                                % parameters of the mixture distribution. 
                                % All elements are nonnegative.
        componentProportion     % Kx1 vector, representing the proportions
                                % of all mixture components in the
                                % distribution.
        logLikelihood           % Log-likelihood achieved during parameter
                                % estimation.
        nIterations             % Number of EM iterations performed for
                                % parameter estimation.
        hasConverged            % This flag indicates if the EM algorithm 
                                % has converged to a local optimum during
                                % parameter estimation.
    end
    
    methods (Static, Hidden)
        function angles = sampleVonMises(mu, kappa, varargin)
            % SAMPLEVONMISES This function generates samples from a 
            %   unimodal von Mises distribution. The sampling scheme used 
            %   by this function was adopted from [1].
            %
            % REQUIRED INPUTS:
            %   mu - Circular mean of the distribution. The parameter mu
            %       must be real valued and between -pi and pi.
            %   kappa - Nonnegative concentration parameter of the
            %       distribution.
            %
            % OPTIONAL INPUTS:
            %   nSamples - Number of samples that should be generated.
            %
            % LITERATURE:
            %   [1] L. Barabesi (1995): "Generating von Mises Variates by
            %       the Ratio-of-Uniforms Method"
            
            % Check inputs
            p = inputParser();
            defaultNSamples = 1;
            
            p.addRequired('mu', @(x) validateattributes(x, ...
                {'numeric'}, {'real', 'scalar', '>=', -pi, '<=', pi}));
            p.addRequired('kappa', @(x) validateattributes(x, ...
                {'numeric'}, {'real', 'nonnegative'}));
            p.addOptional('NSamples', defaultNSamples, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'real', 'scalar', 'nonnegative'}));
            p.parse(mu, kappa, varargin{:});
            
            % Initialize sampling parameter
            if p.Results.kappa > 1.3
                samplingParameter = 1 / sqrt(p.Results.kappa);
            else
                samplingParameter = pi * exp(-p.Results.kappa);
            end
            
            % Allocate output
            angles = zeros(p.Results.NSamples, 1);
            
            % Perform sampling
            for idx = 1 : p.Results.NSamples
                while (true)
                    % Generate two random samples from the uniform
                    % distribution
                    randomSamples = rand(2, 1);
                    
                    % Compute angular value
                    angle = (samplingParameter * ...
                        (2 * randomSamples(2) - 1)) / randomSamples(1);
                    
                    % Check if angle is in valid range. If not, start over.
                    if abs(angle) > pi
                        continue;
                    end
                    
                    % Check stopping condition
                    if p.Results.kappa * cos(angle) < ...
                            2 * log(randomSamples(1)) + p.Results.kappa
                        continue;
                    else
                        break;
                    end
                end
                
                % Assign samples value to output
                angles(idx) = atan2(sin(angle + p.Results.mu), ...
                    cos(angle + p.Results.mu));
            end
        end
        
        function [mu, kappa, cProp] = estimateParameters(angles, gamma)
            % ESTIMATEPARAMETERS This function computes the maximum 
            %   likelihood estimates of the distribution parameters mu, 
            %   kappa and the mixing proportions for a given set
            %   of angular values. The concentration parameter is estimated
            %   using the approximation scheme introduced in [1].
            %
            % REQUIRED INPUTS:
            %   angles - Nx1 vector, containing N angular values, ranged
            %       between -pi and pi.
            %   gamma - NxK responsibility matrix.
            %
            % OUTPUTS:
            %   mu - Kx1 vector, containing the circular means of all K
            %       components of the mixture distribution. The range of 
            %       each element is bounded in [-pi, pi].
            %   kappa - Kx1 vector, containing the concentration parameters
            %       of the mixture distribution.  All elements are 
            %       nonnegative.
            %   cProp - Kx1 vector, representing the proportions of all 
            %       mixture components in the distribution.
            %
            % LITERATURE:
            %   [1] D.J. Best, N.I. Fisher (1981): "The bias of the maximum
            %       likelihood estimators of the von Mises-Fisher
            %       concentration parameters"
            
            % Check inputs
            p = inputParser();
            
            p.addRequired('angles', @(x) validateattributes(x, ...
                {'numeric'}, {'real', 'column', '>=', -pi, '<=', pi}));
            p.addRequired('gamma', @(x) validateattributes(x, ...
                {'numeric'}, {'real', '2d', 'nrows', length(angles)}));
            p.parse(angles, gamma);
            
            % Compute mixing proportions
            cProp = sum(gamma) ./ size(gamma, 1);
            
            % Compute estimation parameters
            x = (gamma' * cos(angles)) ./ sum(gamma)';
            y = (gamma' * sin(angles)) ./ sum(gamma)';
            
            % Compute mean angles
            mu = atan2(y, x);
                        
            % Compute average distances
            d = sqrt(x.^2 + y.^2);
            
            % Use approximation scheme from [1] to estimate kappa
            kappa = zeros(size(gamma, 2), 1);
            
            if any(d < 0.53)
                idx = d < 0.53;
                kappa(idx) = 2 .* d(idx) + d(idx).^3 + ...
                    (5 .* d(idx).^5) ./ 6;
            end
            
            if any(0.53 <= d) && any(d < 0.85)
                idx = (0.53 <= d) & (d < 0.85);
                kappa(idx) = -0.4 + 1.39 .* d(idx) + 0.43 ./ (1 - d(idx));
            end
            
            if any(d >= 0.85)
                idx = d >= 0.85;
                kappa(idx) = 1 ./ (d(idx).^3 - (4 .* d(idx).^2) + ...
                    (3 .* d(idx)));
            end
            
            % Force results to be column vectors
            cProp = cProp(:);
            mu = mu(:);
            kappa = kappa(:);
        end
        
        function [likelihood, compLik] = computeLikelihood(angles, ...
                cProp, mu, kappa)
            % COMPUTELIKELIHOOD This function returns the total likelihood
            %   value and the likelihood for each mixture component for a 
            %   given set of angles.
            %
            % REQUIRED INPUTS:
            %   angles - Nx1 vector, containing N angular values, ranged
            %       between -pi and pi.
            %   cProp - Kx1 vector, representing the proportions of all 
            %       mixture components in the distribution.
            %   mu - Kx1 vector, containing the circular means of all K
            %       components of the mixture distribution. The range of 
            %       each element is bounded in [-pi, pi].
            %   kappa - Kx1 vector, containing the concentration parameters
            %       of the mixture distribution.  All elements are 
            %       nonnegative.
            %
            % OUTPUTS:
            %   likelihood - Nx1 vector containing the likelihood values
            %       for all input angles.
            %   compLik - NxK matrix, containing the component-wise
            %       likelihood values for all input angles.
            
            % Check inputs
            p = inputParser();
            
            p.addRequired('angles', @(x) validateattributes(x, ...
                {'numeric'}, {'real', 'column', '>=', -pi, '<=', pi}));
            p.addRequired('cProp', @(x) validateattributes(x, ...
                {'numeric'}, {'real', 'vector'}));
            p.addRequired('mu', @(x) validateattributes(x, ...
                {'numeric'}, {'real', 'vector','>=', -pi, '<=', pi, ...
                'numel', length(cProp)}));
            p.addRequired('kappa', @(x) validateattributes(x, ...
                {'numeric'}, {'real', 'vector', 'nonnegative', ...
                'numel', length(cProp)}));
            p.parse(angles, cProp, mu, kappa);
            
            % Get number of samples and mixtures
            nSamples = length(p.Results.angles);
            nMixtures = length(p.Results.cProp);
            
            % Initialize component-wise likelihoods
            compLik = zeros(nSamples, nMixtures);
            
            % Compute component-wise likelihoods
            for k = 1 : nMixtures
                compLik(:, k) = ...
                    (1 ./ (2 * pi * besseli(0, p.Results.kappa(k)))) .* ...
                    exp(p.Results.kappa(k) .* ...
                    cos(p.Results.angles - p.Results.mu(k)));
            end
            
            % Compute total likelihood
            likelihood = compLik * p.Results.cProp(:);
        end
    end
    
    methods (Access = public)
        function obj = VonMisesMixture(varargin)
            % VONMISESMIXTURE This class constructor can be used to
            %   either instantiate a "blank" distribution without any
            %   assigned parameters or use additional input arguments to
            %   initialize with a given set of parameters.
            %
            % OPTIONAL INPUTS:
            %   componentProportion - Kx1 vector representing the 
            %       proportions of all mixture components in the
            %       distribution.
            %   mu - Kx1 vector, containing the circular means of all K 
            %       components of the mixture distribution. The range of 
            %       each element must be bounded in [-pi, pi].
            %   kappa - Kx1 vector, containing the concentration
            %       parameters of the mixture distribution. All elements 
            %       must be nonnegative.
            
            % Check inputs
            p = inputParser();
            defaultComponentProportion = 1;
            defaultMu = 0;
            defaultKappa = 1;
            
            p.addOptional('ComponentProportion', ...
                defaultComponentProportion, @(x) validateattributes(x, ...
                {'numeric'}, {'real', 'vector'}));
            p.addOptional('Mu', defaultMu, @(x) validateattributes(x, ...
                {'numeric'}, {'real', 'vector','>=', -pi, '<=', pi, ...
                'numel', length(varargin{1})}));
            p.addOptional('Kappa', defaultKappa, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'real', 'vector', 'nonnegative', ...
                'numel', length(varargin{1})}));
            p.parse(varargin{:});
            
            % Check if component proportions sum to one
            if abs(sum(p.Results.ComponentProportion) - 1) > sqrt(eps)
                error('Component proportions must sum to one.');
            end
            
            % Assign values to object properties
            obj.componentProportion = p.Results.ComponentProportion(:);
            obj.mu = p.Results.Mu(:);
            obj.kappa = p.Results.Kappa(:);
            
            % Get number of mixture components
            obj.nComponents = length(p.Results.ComponentProportion);            
        end
        
        function likelihood = pdf(obj, angles)
            % PDF This function returns the likelihood values for a given
            %   set of angles.
            %
            % REQUIRED INPUTS:
            %   angles - Nx1 vector, containing N angular values, ranged
            %       between -pi and pi.
            %
            % OUTPUTS:
            %   likelihood - Nx1 vector containing the likelihood values
            %       for all input angles.
            %   compLik - NxK matrix, containing the component-wise
            %       likelihood values for all input angles.
            
            % Check inputs
            p = inputParser();
            
            p.addRequired('angles', @(x) validateattributes(x, ...
                {'numeric'}, {'real', 'column', '>=', -pi, '<=', pi}));
            p.parse(angles);
            
            % Initialize output vector
            likelihood = obj.computeLikelihood(angles, ...
                obj.componentProportion, obj.mu, obj.kappa);
        end
        
        function angles = random(obj, varargin)
            % RANDOM This function generates samples from the specified 
            %   mixture of von Mises distributions.
            %
            % OPTIONAL INPUTS:
            %   nSamples - Number of samples that should be generated.
            
            % Check inputs
            p = inputParser();
            defaultNSamples = 1;
            
            p.addOptional('NSamples', defaultNSamples, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'real', 'scalar', 'nonnegative'}));
            p.parse(varargin{:});
            
            % Allocate output
            angles = zeros(p.Results.NSamples, 1);
            
            % A random component index is picked during sampling, based on
            % the "probabilities" given by the individual weights.
            % Therefore, the cumulative distribution has to be computed in
            % advance.
            cumProbs = cumsum(obj.componentProportion);
            
            for idx = 1 : p.Results.NSamples
                % Draw random number from U(0, 1)
                rNumber = rand();
                
                % Select component to sample from
                cIdx = 1 + sum(cumProbs < rNumber);
                
                % Sample from the selected component
                angles(idx) = obj.sampleVonMises(obj.mu(cIdx), ...
                    obj.kappa(cIdx));
            end
        end
        
        function obj = fit(obj, angles, nComponents, varargin)
            % FIT This function estimates the parameters of a mixture of
            %   von Mises distributions using an Expectation-Maximization
            %   scheme. The algorithm used in this function is a highly 
            %   modified version of the basic parameter estimation 
            %   procedure described in [1]. This algorithm uses a different
            %   Maximum-Likelihood estimator for the concentration
            %   parameter and computes soft assignments of the data points
            %   to the mixture components.
            %
            % REQUIRED INPUTS:
            %   angles - Nx1 vector, containing N angular values, ranged
            %       between -pi and pi.
            %   nComponents - Number of mixture components that should be
            %       estimated.
            %
            % PARAMETERS:
            %   ['MaxIter', maxIter] - Maximum number of iterations the
            %       EM-algorithm should run (default = 100).
            %   ['ErrorThreshold', errorThreshold] - Minimum error that
            %       should be used as a stopping-criterion for the
            %       EM-algorithm during convergence testing (default =
            %       1E-4).
            %
            % LITERATURE:
            %   [1] Hung et al. (2012): "Self-updating clustering algorithm
            %       for estimating the parameters in mixtures of von Mises
            %       distributions"
            
            % Check inputs
            p = inputParser();
            defaultMaxIter = 100;
            defaultErrorThreshold = 1E-4;
            
            p.addRequired('angles', @(x) validateattributes(x, ...
                {'numeric'}, {'real', 'vector', '>=', -pi, '<=', pi}));
            p.addRequired('nComponents', @(x) validateattributes(x, ...
                {'numeric'}, {'integer', 'scalar', 'positive'}));
            p.addParameter('MaxIter', defaultMaxIter, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'integer', 'scalar', 'positive'}));
            p.addParameter('ErrorThreshold', defaultErrorThreshold, ...
                @(x) validateattributes(x, {'numeric'}, ...
                {'real', 'scalar', 'nonnegative'}));
            p.parse(angles, nComponents, varargin{:});
            
            % Get number of samples
            nSamples = length(p.Results.angles);
            
            % Run conventional k-means to get an initial clustering
            cIdx = ckmeans(p.Results.angles, p.Results.nComponents, ...
                'Replicates', 10);
            
            % Generate initial gamma matrix (hard assignments from k-means
            % results)
            gamma = ...
                zeros(length(p.Results.angles), p.Results.nComponents);
            for sampleIdx = 1 : nSamples
                gamma(sampleIdx, cIdx(sampleIdx)) = 1;
            end
            
            % Get initial parameter estimates
            [muHat, kappaHat, cPropHat] = ...
                obj.estimateParameters(p.Results.angles, gamma);
            
            % Initialize log-likelihood and status parameters
            logLik = -realmax;
            converged = false;
            
            for k = 1 : p.Results.MaxIter
                % E-Step: Update gamma-matrix
                gamma = ...
                    obj.computeGamma(p.Results.angles, cPropHat, ...
                    muHat, kappaHat);
                
                % M-Step: Re-estimate the distribution parameters
                [muHat, kappaHat, cPropHat] = ...
                    obj.estimateParameters(angles, gamma);
                
                % Evaluate the log-likelihood
                logLikNew = ...
                    sum(log(obj.computeLikelihood(p.Results.angles, ...
                    cPropHat, muHat, kappaHat)));

                % Check for convergence
                if abs(logLik - logLikNew) < p.Results.ErrorThreshold
                    % If converged, save parameters
                    converged = true;
                    
                    % Terminate EM-algorithm
                    break;
                else
                    % If not converged, update log-likelihood and proceed
                    % with next iteration.
                    logLik = logLikNew;
                end
            end
            
            % Initialize model
            obj = VonMisesMixture(cPropHat, muHat, kappaHat);
            obj.logLikelihood = logLik;
            obj.hasConverged = logical(converged);
            obj.nIterations = k;
        end
        
        function [idx, nLogLik, posteriors] = cluster(obj, angles)
            % CLUSTER This functions partitions a set of N angles into K
            %   clusters, where K is determined by the number of mixture
            %   components of the von Mises mixture distribution defined by
            %   obj.
            %
            % REQUIRED INPUTS:
            %   angles - Nx1 vector, containing N angular values, ranged
            %       between -pi and pi.
            %
            % OUTPUTS:
            %   idx - Nx1 vector, containing the cluster indices for each
            %       observation. The cluster index gives the component with
            %       the largest posterior probability for the observation, 
            %       weighted by the component probability.
            %   nLogLik - The negative log-likelihood of the data.
            %   posteriors - NxK matrix, representing the posterior 
            %       probabilities of each component for each observation.
            
            % Check inputs
            p = inputParser();
            
            p.addRequired('angles', @(x) validateattributes(x, ...
                {'numeric'}, {'real', 'column', '>=', -pi, '<=', pi}));
            p.parse(angles);
            
            % Compute the negative log-likelihood
            nLogLik = -sum(log(obj.computeLikelihood(p.Results.angles, ...
                obj.componentProportion, obj.mu, obj.kappa)));
            
            % Compute posterior probabilities
            posteriors = obj.computeGamma(p.Results.angles, ...
                obj.componentProportion, obj.mu, obj.kappa);
            
            % Compute cluster indices
            [~, idx] = max(posteriors, [], 2);
        end
    end
    
    methods (Access = private)
        function gamma = computeGamma(obj, angles, cProp, mu, kappa)
            % COMPUTEGAMMA This function computes the responsibility matrix
            %   for a given set of parameter values.
            %
            % REQUIRED INPUTS:
            %   angles - Nx1 vector, containing N angular values, ranged
            %       between -pi and pi.
            %   cProp - Kx1 vector, representing the proportions of all
            %       mixture components in the distribution.
            %   mu - Kx1 vector, containing the circular means of all K
            %       components of the mixture distribution. The range of
            %       each element is bounded in [-pi, pi].
            %   kappa - Kx1 vector, containing the concentration parameters
            %       of the mixture distribution.  All elements are
            %       nonnegative.
            %
            % OUTPUTS:
            %   gamma - NxK responsibility matrix.
            
            % Check inputs
            p = inputParser();
            
            p.addRequired('angles', @(x) validateattributes(x, ...
                {'numeric'}, {'real', 'column', '>=', -pi, '<=', pi}));
            p.addRequired('cProp', @(x) validateattributes(x, ...
                {'numeric'}, {'real', 'vector'}));
            p.addRequired('mu', @(x) validateattributes(x, ...
                {'numeric'}, {'real', 'vector','>=', -pi, '<=', pi, ...
                'numel', length(cProp)}));
            p.addRequired('kappa', @(x) validateattributes(x, ...
                {'numeric'}, {'real', 'vector', 'nonnegative', ...
                'numel', length(cProp)}));
            p.parse(angles, cProp, mu, kappa);
            
            % Get component-wise likelihoods
            [~, cLik] = obj.computeLikelihood(p.Results.angles, ...
                p.Results.cProp, p.Results.mu, p.Results.kappa);
            
            % Compute gamma-matrix
            cGammas = bsxfun(@times, cLik, cProp');
            gamma = bsxfun(@times, cGammas, 1 ./ sum(cGammas, 2));
        end
    end
end