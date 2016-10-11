% 'ObjectDetectionKS' class
% This knowledge source aims at determining if a new object has appeared in the scene or not
% Author: Benjamin Cohen-Lhyver
% Date: 26.09.16
% Rev. 1.0

classdef ObjectDetectionKS < AbstractKS

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)
    htm; % Head_Turning_Modulation KS
    RIR; % Robot_Internal_Representation KS
    
    MOKS; % Motor_Order KS
    
    ALKS; % Audio_Localization KS
    VLKS; % Visual_Localization KS
    ACKS; % Audio_Classification_Experts KS
    VCKS; % Visual_Classification_Experts KS

    % decision = [];

    thr_theta;

end
% ======================== %
% === PROPERTIES [END] === %
% ======================== %

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === CONSTRUCTOR [BEG] === %
function obj = ObjectDetectionKS (bbs, htm)
    obj = obj@AbstractKS();
    obj.bbs = bbs;
    obj.invocationMaxFrequency_Hz = inf;

    obj.htm = htm;
    obj.RIR = htm.RIR;
    obj.ALKS = htm.ALKS;
    obj.VLKS = htm.VLKS;
    obj.ACKS = htm.ACKS;
    obj.VCKS = htm.VCKS;
    obj.thr_theta = getInfo('thr_theta');
end
% === CONSTRUCTOR [END] === %


function [b, wait] = canExecute (obj)
    b = true;
    wait = false;
end

% function [create_new, do_nothing] = simulationStatus (obj, iStep)
function execute (obj)

    theta_a = obj.ALKS.getAudioLocalization();
    if theta_a == -1
        obj.decision(:, end+1) = [0 ; 0];
        return;
    end

    theta_v = obj.VLKS.getVisualLocalization();

    putative_audio_object = [];
    % putative_visual_objects = [];

    nb_objects = obj.RIR.nb_objects;

    % objects_vec = 1:obj.RIR.nb_objects;
    % if obj.htm.iSource ~= 0 %&& obj.RIR.nb_objects > 1
    %   objects_vec(obj.htm.iSource) = [];
    % end
    % --- Look for an object that has already been observed
    for iObject = 1:obj.RIR.nb_objects
        % theta_o = getObject(obj.htm, iObject, 'theta_hist');
        % theta_o = theta_o(end);
        theta_o = getObject(obj.htm, iObject, 'theta');
        theta_diff_a = abs(theta_o - theta_a);
        % theta_diff_v = abs(theta_o - theta_v);

        if theta_diff_a <= obj.thr_theta && obj.htm.sources(obj.htm.iStep) ~= 0
            putative_audio_object(end+1, :) = [iObject, theta_o];
            if size(putative_audio_object, 1) > 1
                previous_theta = getObject(obj.htm, putative_audio_object(1), 'theta');
                [tmp, pos] = min(putative_audio_object(:, 2));
                % if pos == 2
                    putative_audio_object = putative_audio_object(pos, :);
                % end
            end
        end
        % if theta_diff_v <= obj.htm.theta_thr
        %   putative_visual_objects(:, end+1) = [iObject ; theta_diff_v];
        % end
    end

    if isempty(putative_audio_object)
        hyp = [1 ; nb_objects+1];
    else
        hyp = [2 ; putative_audio_object(1)];
    end
    % obj.decision(:, end+1) = hyp;

    obj.blackboard.addData('objectDetectionHypothese',...
                           hyp,...
                           false,...
                           obj.trigger.tmIdx);
    
    notify(obj, 'KsFiredEvent');
end

% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === CLASS [END] === % 
% =================== %
end