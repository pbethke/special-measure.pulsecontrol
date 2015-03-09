classdef NullAWG < AWG
    properties (Constant,GetAccess = public)
        nChannels = 2
        possibleResolutions = 14
    end
    
    methods
        function obj = NullAWG()
            obj = obj@AWG(1);
        end
        
        function addPulseGroup(self,grpdef)
        end
        
        %remove this pulsegroup from memory and forget about it
        function removePulseGroup(self,name)
        end
        
        %update the changed pulses
        function updatePulseGroup(self,grpdef)
        end
        
        %wait for trigger
        function arm(self)
        end
        
        %this function is for debugging purposes
        function issueSoftwareTrigger(self)
        end
        
        function val = isPlaybackInProgress(self)
        end
    end
end