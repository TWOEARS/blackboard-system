classdef GroundTruthPlotKS < AuditoryFrontEndDepKS

    properties (SetAccess = private)
        labels;
        onOffsets;
        activity;
        azms;
        curActiveLabels;
        curActivity;
        curTimeRange;
    end

    methods
        function obj = GroundTruthPlotKS(labels,onOffsets,activity,azms)
            requests{1}.name = 'time';
            requests{1}.params = genParStruct();
            obj = obj@AuditoryFrontEndDepKS(requests);
            obj.invocationMaxFrequency_Hz = inf;
            obj.labels = labels;
            obj.onOffsets = onOffsets;
            obj.activity = activity;
            obj.azms = azms;
            obj.curTimeRange = [0 0];
        end

        function delete(obj)
        end

        function [b, wait] = canExecute(obj)
            b = true;
            wait = false;
        end
        
        function setYLimTimeSignal(obj, ylim)
            obj.ylim_timSignal = ylim;
        end

        function execute(obj)
            obj.curTimeRange(1) = obj.curTimeRange(2);
            obj.curTimeRange(2) = obj.blackboard.currentSoundTimeIdx;
            obj.curActiveLabels = {};
            obj.curActivity = {};
            for nn = 1 : numel( obj.azms )
                isEventInTimeRange = ...
                    ((obj.onOffsets{nn}(:,1) >= obj.curTimeRange(1)) & (obj.onOffsets{nn}(:,1) <= obj.curTimeRange(2)))  | ...
                    ((obj.onOffsets{nn}(:,2) >= obj.curTimeRange(1)) & (obj.onOffsets{nn}(:,2) <= obj.curTimeRange(2)))  | ...
                    ((obj.onOffsets{nn}(:,1) <= obj.curTimeRange(1)) & (obj.onOffsets{nn}(:,2) >= obj.curTimeRange(2)));
                obj.curActiveLabels{nn} = obj.labels{nn}(isEventInTimeRange);
                sampleRange = max( [1 1;round( obj.curTimeRange * 44100 )], [], 1 );
                obj.curActivity{nn} = any( obj.activity{nn}(sampleRange(1):sampleRange(2)) );
            end
        end
        
        % Visualisation
        function visualise(obj)
            if ~isempty(obj.blackboardSystem.locVis)
                nSources = size(obj.azms, 1);
                % Plot ground true source positions
                for nn = 1:nSources
                    if ~isempty( obj.curActiveLabels{nn} )
                        obj.blackboardSystem.locVis.plotMarkerAtAngle(...
                            nn, obj.azms(nn), obj.curActiveLabels{nn}{1});
                    elseif obj.curActivity{nn}
                        obj.blackboardSystem.locVis.plotMarkerAtAngle(...
                            nn, obj.azms(nn), 'unspecified');
                    else
                        obj.blackboardSystem.locVis.plotMarkerAtAngle(...
                            nn, obj.azms(nn), 'CLEAR');
                    end
                end
            end
        end
    end
        
end

% vim: set sw=4 ts=4 et tw=90 cc=+1:
