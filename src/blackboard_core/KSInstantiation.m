classdef KSInstantiation < handle
    
    properties (SetAccess = private)
        ks;            % Triggered knowledge source
        rank;          % Importance rank of KSs between [0 100]
    end
    
    methods
        function obj = KSInstantiation(ks, rank)
            obj.ks = ks;
            if nargin < 2
                rank = 0;
            end
            obj.rank = rank;
        end
        function setRank(obj, rank)
            obj.rank = rank;
        end
    end
    
end
