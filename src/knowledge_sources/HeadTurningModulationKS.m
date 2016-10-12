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
 
    current_time = 0;

    % MotorOrderKS;
    % HTMFocusKS;
    
    RIR; % Robot_Internal_Representation class
    MSOM; % Multimodal_Self_Organizing_Map class
    MFI; % Multimodal_Fusion_&_Inference class
    % MotorOrderKS;
    % HTMFocusKS; % Head_Turning_Modulation_Focus class
    EMKS; % Environmental_Map class
    % ObjectDetectionKS;
    % ALKS;
    % VLKS;
    % ACKS;
    % VCKS;

    statistics = [];

    sources = [];

    current_object = 0;
    current_object_hist = [];

    info;

    iStep = 0;

    save = false;
    load = false;
    continue_simulation = false;

end


% properties (SetAccess = public, GetAccess = public)
%     cpt = 0;
%     last_movement = 0;
%     theta_hist = [];
% end
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
    
    initializeParameters();

    obj.MSOM = MultimodalSelfOrganizingMap();
    obj.MFI = MultimodalFusionAndInference(obj);
    obj.RIR = RobotInternalRepresentation(obj);
    
    % obj.HTMFocusKS = HTMFocusKS(obj);
    % obj.MotorOrderKS = MotorOrderKS(obj, obj.HTMFocusKS);
    
    % obj.EMKS = EnvironmentalMapKS(obj);

    % obj.ALKS = AudioLocalizationKS(obj);
    % obj.VLKS = VisualLocalizationKS(obj);

    % obj.ACKS = AudioClassificationExpertsKS(obj);
    % obj.VCKS = VisualClassificationExpertsKS(obj);

    % obj.ObjectDetectionKS = ObjectDetectionKS(obj);

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

    obj.cpt = obj.cpt + 1;

    object_detection = obj.blackboard.getLastData('objectDetectionHypothese').data;
    object_detection = object_detection(1); % --- 1st value: 1(create object) or 2(update object)
    obj.current_object = object_detection(2); % --- 2nd value: id of the object. ≠ from focus!
    % object_detection = obj.ObjectDetectionKS.decision(1, end); 
    % obj.current_object = obj.ObjectDetectionKS.decision(2, end); 
    obj.current_object_hist(end+1) = obj.current_object; % --- Update history of sources

    data = getClassifiersOutput(obj);
    audio_theta = getLocalisationOutput();

   if object_detection == 1 % --- Create new object
        % theta = generateAngle(obj.gtruth{iStep, 1});
        % audio_theta = obj.ALKS.hyp_hist(end); % --- Grab the audio localization output
        %visual_theta = obj.VLKS.getVisualLocalization(); % --- Grab the visual localization output

        % obj.degradeData(audio_theta, iStep); % --- Remove visual components if object is NOT in field of view
        obj.MSOM.idx_data = 1; % --- Update status of MSOM learning

        obj.RIR.updateData(data, audio_theta); % --- Updating the RIR observed data
        obj.RIR.addObject(); % --- Add the object
        setObject(obj, obj.current_object, 'presence', true); % --- The object is present but not necessarily facing the robot
        % setObject(obj, 0, 'presence', true);

    % elseif ~create_new && ~do_nothing % --- update object
    elseif object_detection == 2 % --- Update object
        % theta = getObject(obj, obj.current_object, 'theta');
        % theta = obj.ALKS.hyp_hist(end); % --- Grab the audio localization output

        % obj.degradeData(theta, iStep); % --- Remove visual components if object is NOT in field of view
        obj.RIR.updateData(data, audio_theta); % --- Updating the RIR observed data
        obj.RIR.updateObject(); % --- Update the current object
        obj.MSOM.idx_data = obj.MSOM.idx_data+1;
        setObject(obj, obj.current_object, 'presence', true); % --- The object is present but not necessarily facing the robot

    % elseif ~create_new && do_nothing % --- silence phase
    elseif object_detection == 0 % --- silence phase
        if obj.RIR.nb_objects > 0 && getObject(obj, obj.current_object_hist(end-1), 'presence') && obj.current_object_hist(end-1) ~= 0
            setObject(obj, obj.current_object_hist(end-1), 'presence', false);
            o = obj.RIR.getEnv().objects{obj.current_object_hist(end-1)}.theta_hist(1);
            obj.RIR.getEnv().objects{obj.current_object_hist(end-1)}.theta_hist(end+1) = o;
            obj.RIR.getEnv().objects{obj.current_object_hist(end-1)}.theta = o;
            % obj.RIR.getLastObj().presence = false;
        end
        obj.RIR.updateData(obj.data(:, iStep), -1);
    end

    % --- Update all objects
    obj.updateTime();

    obj.RIR.updateObjects();

    obj.updateAngles();


    % if ~isempty(classifiers_output)
    %     obj.data(:, obj.cpt) = classifiers_output;
    % else
    %     obj.data(:, obj.cpt) = generateEmptyVector();
    % end

    % if obj.blackboard.currentSoundTimeIdx > getInfo('duration')
    %     obj.blackboardSystem.robotConnect.finished = true;
    %     playNotification();
    % end

    notify(obj, 'KsFiredEvent');
% end
end

function updateTime (obj)
    obj.current_time = obj.blackboard.currentSoundTimeIdx;
end


function updateAngles (obj)
    if obj.current_object == 0
        return;
    end
    head_position = obj.RIR.head_position;
    objects_id = 1:obj.RIR.nb_objects;
    objects_id(obj.current_object) = [];
    
    if isempty(objects_id)
        return;
    end

    for iObject = objects_id
        previous_theta = getObject(obj, iObject, 'theta_hist');
        theta = abs(head_position - previous_theta(end));
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

end
    
end
