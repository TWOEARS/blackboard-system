% 'HeadTurningModulationKS' class
% This knowledge source triggers head movements based on two modules:
% 1. MultimodalFusionAndInference module;
% (reference: Benjamin Cohen-Lhyver, Multimodal Fusion and Inference Using Binaural Audition and Vision, ICA 2016)
% 2. Dynamic Weighing module 
% (reference: Benjamin Cohen-Lhyver, Modulating the Auditory Turn-to Reflex on the Basis of Multimodal Feedback Loops:
% the Dynamic Weighting Model, in IEEE-ROBIO 2015)
% Author: Benjamin Cohen-Lhyver
% Date: 01.06.16
% Rev. 2.0

classdef HeadTurningModulationKS < AbstractKS
% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public)
    head_position = 0;
 
    bbs = [];

    data = [];
    theta = [];
    theta_v = [];
 
    current_time = 0;
    
    current_object = 0;

    RIR; % Robot Internal Representation
    MSOM; % Multimodal SelfOrganizing Map
    MFI; % Multimodal Fusion & Inference

    % EMKS; % Environmental_Map class

    statistics = [];

    sources = [];

    iStep = 0;

    % save = false;
    % load = false;
    % continue_simulation = false;

end
% ======================== %
% === PROPERTIES [END] === %
% ======================== %

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

function obj = HeadTurningModulationKS (bbs)
    obj = obj@AbstractKS();
    obj.bbs = bbs;
    obj.invocationMaxFrequency_Hz = inf;
    
    initializeParameters(obj);

    obj.MSOM = MultimodalSelfOrganizingMap();
    obj.MFI = MultimodalFusionAndInference(obj);
    obj.RIR = RobotInternalRepresentation(obj);
end

% === Execute functionality
function [b, wait] = canExecute (obj)
    b = true;
    wait = false;
end

function finished = isFinished(obj)
    finished = obj.finished;
end

% === 'RUN' FUNCTION [BEG] === %
function execute (obj)
    
    fprintf('\nHead Turning Modulation KS evaluation\n');

    obj.iStep = obj.iStep + 1;

    obj.data(:, end+1) = getClassifiersOutput(obj);
    obj.theta(end+1) = getLocalisationOutput(obj);
    tmp = obj.blackboard.getLastData('audiovisualHypotheses').data;
    obj.theta_v(end+1) = tmp('theta');
    
    object_detection = obj.blackboard.getData('objectDetectionHypotheses').data;
    obj.current_object = object_detection.id_object;

    if ~obj.createNew() && ~obj.updateObject()
        obj.setPresence(false);
        obj.RIR.updateData();
    else
        obj.degradeData(obj.theta); % --- Remove visual components if object is NOT in field of view
        obj.RIR.updateData(); % --- Updating the RIR observed data
        if obj.createNew()
            obj.MSOM.idx_data = 1; % --- Update status of MSOM learning
            obj.RIR.addObject(); % --- Add the object
        elseif obj.updateObject()
            obj.MSOM.idx_data = obj.MSOM.idx_data+1;
            obj.RIR.updateObject(); % --- Update the current object
        end
        obj.setPresence(true);
    end

    % --- Update all objects
    obj.RIR.updateObjects();

    obj.updateAngles();
% 
%     if sum(obj.data(getInfo('nb_audio_labels')+1:end, obj.iStep)) == 0
%         obj.statistics.max_shm(iStep) = 0;
%     end

    % obj.retrieveMfiCategorization();

    % obj.storeMsomWeights(iStep);

    % obj.EMKS.updateMap();


    % if ~isempty(classifiers_output)
    %     obj.data(:, obj.cpt) = classifiers_output;
    % else
    %     obj.data(:, obj.cpt) = generateEmptyVector();
    % end

    % if obj.blackboard.currentSoundTimeIdx > getInfo('duration')
    %     obj.blackboardSystem.robotConnect.finished = true;
    %     playNotification();
    % end

    keySet = {'detectedObjects'};
    valueSet = {getObject(obj, 'all')};

    observedObjectsHypotheses = containers.Map(keySet, valueSet);

    obj.blackboard.addData('ObservedObjectsHypotheses', observedObjectsHypotheses,...
                           false, obj.trigger.tmIdx);

    notify(obj, 'KsFiredEvent');
% end
end

function setPresence (obj, bool)
    if ~bool 
        if obj.RIR.nb_objects > 0 
            object_detection = obj.blackboard.getData('objectDetectionHypotheses').data;
            idx = object_detection.id_object;
            idx = idx(end-1);
            if idx ~= 0 && getObject(obj, idx, 'presence')
                setObject(obj, idx, 'presence', false);
            end
        end
    else
        object_detection = obj.blackboard.getLastData('objectDetectionHypotheses').data;
        idx = object_detection.id_object;
        setObject(obj, idx, 'presence', true); % --- The object is present but not necessarily facing the robot
    end
end

function bool = createNew (obj)
    object_detection = obj.blackboard.getLastData('objectDetectionHypotheses').data;
    bool = object_detection.create_new;
end

function bool = updateObject (obj)
    object_detection = obj.blackboard.getLastData('objectDetectionHypotheses').data;
    bool = object_detection.update_object;
end

function updateTime (obj)
    obj.current_time = obj.blackboard.currentSoundTimeIdx;
end

% === Given the position of the head, updates the position of all the sources observed so far
function updateAngles (obj)
    if obj.RIR.nb_objects == 0
        return;
    end
    motor_order = obj.blackboard.getLastData('motorOrder');
    if isempty(motor_order)
        return;
    end
    motor_order = motor_order.data('theta');
    for iObject = 1:obj.RIR.nb_objects
        theta_object = getObject(obj, iObject, 'theta');
        
        
        theta = mod(360 - motor_order + theta_object(end), 360);
        obj.RIR.getEnv().objects{iObject}.updateAngle(theta);
    end
end

% function retrieveMfiCategorization (obj, classifiers_output)
%     if ~isempty(classifiers_output)
%         obj.classif_mfi{obj.cpt} = obj.RIR.getMFI().inferCategory(classifiers_output) ;
%     else
%         obj.classif_mfi{obj.cpt} = 'none_none' ;
%     end
% end

% === TO BE MODIFIED === %
% Need to find a way to retrieve the groundtruth knowledge
% for statistical purposes.

% function retrieveGroundtruth (obj)
%     % obj.gtruth = cell(obj.RIR.nb_objects, 1) ;
%     al = 0 ;
%     vl = 0 ;

%     al = obj.simulation_status(1, obj.cpt) ;
%     vl = obj.simulation_status(2, obj.cpt) ;

%     if al == 0
%         obj.gtruth{end+1} = 'none_none' ;
%     else
%         obj.gtruth{end+1} = [obj.visual_labels{vl}, '_', obj.audio_labels{al}] ;
%     end

% end
% === TO BE MODIFIED === %

function degradeData (obj, theta)
    if ~isInFieldOfView(theta)
        obj.data(getInfo('nb_audio_labels')+1:end, obj.iStep) = 0;
    end
end

end
% ===================== %
% === METHODS [END] === % 
% ===================== %
end
% =================== %
% === END OF FILE === %
% =================== %