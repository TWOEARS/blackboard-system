% 'MotorOrderKS' class
% Author: Benjamin Cohen-Lhyver
% Date: 01.06.16
% Rev. 1.0
classdef MotorOrderKS < AbstractKS

% ======================== %
% === PROPERTIES [BEG] === %
% ======================== %
properties (SetAccess = public, GetAccess = public)
    head_position = 0;
    head_position_hist = [];
    % htm;
    % RIR;
    HTMFocusKS;
    shm;
    % robot;
    % cpt = 0;
    % last_movement = 0;

end
% ======================== %
% === PROPERTIES [END] === %
% ======================== %

% ===================== %
% === METHODS [BEG] === %
% ===================== %
methods

% === CONSTRUCTOR [BEG] === %
function obj = MotorOrderKS (robot)
    obj = obj@AbstractKS();
    obj.invocationMaxFrequency_Hz = inf;
    obj.robot = robot;
    % obj.RIR = htm.RIR;
end
% === CONSTRUCTOR [END] === %

function [b, wait] = canExecute (obj)
    b = true;
    wait = false;
end

function execute (obj)
    currentHeadOrientation = obj.blackboard.getLastData('headOrientation').data;
    htm = findKS(obj, 'HeadTurningModulationKS');
    RIR = htm.RIR;
    
    focus = obj.blackboard.getLastData('FocusedObject');
    focus = focus.data('focus');

    if focus == 0
        theta = -currentHeadOrientation;

    % --- Line above to be deleted -> already handle in the MotorOrderKS
    elseif obj.isFocusedObjectPresent() %&& focus ~= 0   % --- move the head to 'theta'
        theta = getObject(obj.RIR, focus, 'theta');
        % --- TO BE PLACED IN OBJECTDETECTIONKS
        % --- It's not up to this KS to set a new property to the object (-> AUDIOLOCALIZATIONKS)
        setObject(obj.RIR, focus, 'theta', 0);
    else                                            % --- go back to resting position (O°)
        theta = -currentHeadOrientation;
        original_theta = getObject(obj.htm, focus, 'theta_hist');
        setObject(obj.RIR, focus, 'theta', original_theta(1));
        obj.RIR.getEnv().objects{focus}.theta_hist(end+1) = original_theta(1);
    end

    obj.robot.moveRobot(0, 0, theta);
    
    obj.blackboard.addData('motorOrder', [currentHeadOrientation, theta],...
                           true, obj.trigger.tmIdx);
    notify(obj, 'KsFiredEvent', BlackboardEventData(obj.trigger.tmIdx));

    % obj.head_position = mod(theta+obj.head_position, 360);
    obj.head_position = theta;
    obj.head_position_hist(end+1) = theta;

    obj.RIR.head_position = obj.head_position;

    obj.computeSHM();

    % obj.cpt = obj.cpt+1;
    
    % if ~isSoundPresent(obj)
    %     theta = -currentHeadOrientation;
    % % --- Turn to the sound source
    % %elseif focus ~= 0 && isFocusedObjectPresent(RIR)
    % elseif focus ~= 0 && getObject(RIR, focus, 'presence')
    %     % --- Smoothing the head movements
    %     if obj.cpt - obj.last_movement >= getInfo('smoothing_head_movements')
    %         obj.last_movement = obj.cpt;
    %         %theta = RIR.motorOrder();
    %         theta = getObject(RIR, focus, 'theta');
    %     else
    %         theta = 0;
    %     end
    % elseif isempty(RIR.getMFI().categories)
    %     if obj.cpt - obj.last_movement >= 1
    %         theta = getObject(RIR, 0, 'theta');
    %         obj.last_movement = obj.cpt ;
    %     else
    %         theta = 0;
    %     end
    % else
    %     theta = 0;
    % end

    % data = getData(htm, 0); % --- get the data of the last object detected
    
    % na = getInfo('nb_audio_labels');
    % if theta < 20 && sum(data(na+1:end, end)) == 0
    %     theta = 180;
    % end
    % if theta > 340 && sum(data(na+1:end, end)) == 0
    %     theta = 180;
    % end

    % if theta < 15
    %     theta = 0;
    % end

    % obj.robot.moveRobot(0, 0, theta);
    
    % obj.blackboard.addData( 'motorOrder', [currentHeadOrientation, theta], true, obj.trigger.tmIdx);
    % notify(obj, 'KsFiredEvent', BlackboardEventData(obj.trigger.tmIdx));

end


% function moveHead (obj)
% 	robot = obj.htm.robot;
%     % --- If no sound -> make the head turn to 0� (resting state)
%     focus = robot.focus;

%     if obj.isFocusedObjectPresent() && focus ~= 0
%         % theta = obj.motorOrder();
%         theta = getObject(robot, robot.focus, 'theta');
%         % obj.robot.updateAngle(0);
%         setObject(robot, 0, 'theta', 0);
%         %robot.getLastObj().theta = 0;
%     else
%         theta = -obj.head_position;
%     end
%     obj.head_position = mod(theta+obj.head_position, 360) ;
%     obj.head_position_hist(end+1) = obj.head_position;
% end

% function bool = isFocusedObjectPresent (obj)
% 	robot = obj.htm.robot;
%     if isempty(robot.getEnv().present_objects)
%         bool = false ;
%     elseif find(robot.focus == robot.getEnv().present_objects)
%         bool = true ;
%     else
%         bool = false ;
%     end
% end

function bool = isFocusedObjectPresent (obj)
    focus = obj.HTMFocusKS.focused_object;

    if obj.RIR.nb_objects == 0
        bool = false;
    elseif getObject(obj.RIR, focus, 'presence')
        bool = true;
    else
        bool = false;
    end
end

function computeSHM (obj)
    if numel(obj.head_position_hist) > 1
        if obj.head_position_hist(end-1) ~= obj.head_position_hist(end)
            obj.shm = obj.shm+1;
        end
    end
end


function finished = isFinished(obj)
    finished = obj.finished;
end

% ===================== %
% === METHODS [END] === %
% ===================== %
end
% =================== %
% === END OF FILE === %
% =================== %
end