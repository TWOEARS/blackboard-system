classdef (ConstructOnLoad) BlackboardEventData  < event.EventData
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
      data = 0;
    end
   
    methods
      function obj = BlackboardEventData(data)
            obj.data = data;
      end
    end
   
end

