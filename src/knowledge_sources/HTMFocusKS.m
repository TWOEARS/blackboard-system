% 'HTMFocusKS' class
% This knowledge source compute the object to be focused on.
% It is based on two distinct algorithms:
% 1. The Dynamic Weighting module
% 2. The Multimodal Fusion & Inference module
% Author: Benjamin Cohen-Lhyver
% Date: 01.06.16
% Rev. 2.0

classdef HTMFocusKS < AbstractKS
% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public)
    htm; 
    RIR;

    bbs;
 
    % current_time = 0;
    % mfiFocus = 0;
    % dwFocus = 0;

    focused_object = 0;
    focus_origin = 0; % to be renamed as "focus_type"
    previous_focus = 0;
    focus_hist = 0;

    shm = 0;

end

% ===================== %
% === METHODS (BEG) === %
% ===================== %
methods

% === Constructor === %
function obj = HTMFocusKS (bbs, htm)
    obj = obj@AbstractKS();
    obj.bbs = bbs;
    obj.invocationMaxFrequency_Hz = inf;

    obj.htm = htm;
    
    obj.RIR = htm.RIR;

end


% === Other Methods === %
% --- Execute functionality
function [b, wait] = canExecute (obj)
    b = true;
    wait = false;
end

function execute (obj)
    RIR = obj.RIR; % --- RobotInternalRepresentaion

    if RIR.nb_objects == 0
        obj.blackboard.addData('FocusedObject', 0,...
                               false, obj.trigger.tmIdx);
        notify(obj, 'KsFiredEvent');
        return;
    end
    
    % --- DWmod-based focus computing
    dwmod_focus = obj.computeDWmodFocus();

    % --- MFI-based focus computing
    mfi_focus = obj.computeMFIFocus();

    % --- Comparison of the two results
    if mfi_focus == 0 && dwmod_focus ~= 0 % DWmod takes the lead
        focus = dwmod_focus;
        focus_origin = 1;
    elseif mfi_focus == 0 && dwmod_focus == 0 % No focused object
        focus = obj.focus_hist(end);
        % focus = 0;
        focus_origin = 0;
    else % MFImod takes the lead over the DWmod
        focus = mfi_focus;
        focus_origin = -1;
    end

    if ~obj.isPresent(focus)
        focus = 0;
    end

    obj.focused_object = focus;
    obj.focus_origin(end+1) = focus_origin;
    obj.focus_hist(end+1) = obj.focused_object;

    % --- List the focus
    focusedObject = containers.Map({'focus', 'focus_origin'},...
                                   {focus, focus_origin});

    obj.blackboard.addData('FocusedObject', focusedObject,...
                            false, obj.trigger.tmIdx);
    notify(obj, 'KsFiredEvent');

end

% === Compute focused object thanks to the DYNAMIC WEIGHTING module (DWmod) algorithm
function focus = computeDWmodFocus (obj)
    focus = obj.getMaxWeightObject();
    object = getObject(obj.RIR, focus);
    if object.weight < 0.98
        focus = 0;
    elseif ~obj.isPerformant(object.cat)
        focus = 0;
    end
end

% === Compute focused object thanks to the MULTIMODAL FUSION and INFERENCE module (MFImod) algorithm
function focus = computeMFIFocus (obj)
    focus = 0;
    current_object = obj.htm.current_object;
    % current_object = obj.focused_object;
    if current_object == 0
        focus = 0;
        return;
    end

    if getObject(obj.RIR, current_object, 'presence')
        request = getObject(obj.RIR, current_object, 'requests');
        if request.check 
            % focus = numel(obj.RIR.getEnv().objects);
            focus = current_object;
            obj.RIR.getEnv().objects{current_object}.requests.checked = true;
        elseif request.checked
            % focus = numel(obj.RIR.getEnv().objects);
            focus = current_object;
        end
    end
end

% === Check if the considered object is present in the environment
function bool = isPresent (obj, idx)
    if find(idx == obj.RIR.getEnv().present_objects)
        bool = true;
    else
        bool = false;
    end 
end

function bool = isPerformant (obj, idx)
    env = obj.RIR.getEnv();
    perf = cell2mat(getCategory(env, idx, 'perf'));
    if perf >= getInfo('q') && perf < 1
    % if obj.observed_categories{idx}.perf >= getInfo('q') && obj.observed_categories{idx}.perf < 1
        bool = true;
        % if obj.observed_categories{idx}.perf == 1 && obj.observed_categories{idx}.nb_inf < 7
        %   bool = false;
        % end
    else
        bool = false;
    end
end

function computeSHM (obj)
    if obj.focused_object ~= obj.previous_focus && obj.focused_object ~= 0
        obj.shm = obj.shm + 1;
        obj.previous_focus = obj.focused_object;
    end
end


% === Get Objects of Max Weight (DWmod computation)
function request = getMaxWeightObject (obj)
    RIR = obj.RIR;
    obj_weights = getObject(RIR, 'all', 'weight');
    [val, pos] = max(obj_weights);
    max_weight_obj = find(obj_weights == val);
    if numel(max_weight_obj) > 1
        tsteps = getObject(RIR, max_weight_obj, 'tsteps');
        [~, pos] = min(tsteps);
        request = max_weight_obj(pos);
    else
        request = pos;
    end
    request = int32(request);
end


end

% ===================== %
% === Methods (END) === %
% ===================== %



end