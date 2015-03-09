classdef AWG < handle & matlab.mixin.Heterogeneous
    % AWG interface class which provides a generic interface to any
    % arbitrary wavfeform generetor. The hardware specific implementation
    % is done in derived classes. By deriving from the SuperClass handle
    % an AWG instance is always a reference to an object.
    
    % defining properties of an harware instrument
    properties (Constant,Abstract,GetAccess = public)
        nChannels
        possibleResolutions
    end
    
    % object specific generic AWG properties
    properties (GetAccess = public, SetAccess=protected)
        identifier;
        
        %pulse to waveform conversion settings
        resolution; %in bits
        clk;
        offset;
        scale;
        
        storedPulsegroups = AWGSTORAGE();
        activePulsegroup = 'none';
        
    end
    
    % hardware specific methods
    methods (Abstract)
        %make this pulsegroup playable by AWG
        addPulseGroup(self,grpdef);
        
        %remove this pulsegroup from memory and forget about it
        removePulseGroup(self,name);
        
        %update the changed pulses
        updatePulseGroup(self,grpdef);
        
        %wait for trigger
        arm(self);
        
        %this function is for debugging purposes
        issueSoftwareTrigger(self);
        
        val = isPlaybackInProgress(self);
        
%         %add a pulsegroup by name to the pulsegroups playable by this
%         %machineuse is/ deprecated
%         add(self,pulsegroup)
%         
%         load(self,grp, ind)
%         
%         erase(self,groups,options)
%         
%         syncwaveforms(self)
%         
%         rm(self,grp, ctrl)
    end
    
    % Set methods controlling if argument is valid
    methods
        function obj = AWG(id)
            obj.identifier = id;
            
            obj.offset = zeros(1,obj.nChannels);
            obj.scale = ones(1,obj.nChannels);
            obj.resolution = obj.possibleResolutions(1);
        end
        
        function setActivePulseGroup(self,pulsegroupName)
            if isKey(self.storedPulsegroups,pulsegroupName)
                self.activeSequence = pulsegroupName;
            else
                error('Can not activate pulsegroup "%s". Since it is not known',sequenceName);
            end
        end
        
        % set mapping function: output = scale * x + offset
        function setVoltageMapping(this,channel,newScale,newOffset)
            if channel>this.nChannels
                error('Unknown channel %i',channel);
            end
            this.scale(channel) = newScale;
            this.offset(channel) = newOffset;
        end
        
        % set output resolution to bits if it is allowed
        function setResolution(self,bits)
            
            if find(self.possibleResolutions==bits)
                self.resolution = bits;
            else
                disp(bits)
                error('%s does not support this resolution.',self.type)
            end
        end
        
        % set zerolen to positive pulselength if pulse is zero, otherwise
        % to negative pulselength
        function zerolen = zeroLength(self,grp,ind,zerolen)
            
            if isempty(ind)
                ind = 1:length(grp.pulses);
            end
            
            epsilon = self.scale/2^(self.resolution-1);
            for i = 1:length(grp.pulses)
                
                dind = find([grp.pulses(i).data.clk] == self.clk);
                npts = size(grp.pulses(i).data(dind).wf, 2);
                
                for virtChan=1:size(grp.pulses(i).data(dind).wf,1)
                    
                    hardChan = self.getHardwareChannel(grp.chan(virtChan));
                    
                    if hardChan
                    
                        if any(abs(grp.pulses(i).data(dind).wf(virtChan,:)) > epsilon(hardChan) )
                            zerolen(ind(i),virtChan) = -npts;
                        else
                            zerolen(ind(i),virtChan) = npts;
                        end
                    
                    end
                end
                
            end
            
        end
        
    end
    
    methods (Static)
        
    end
    
end