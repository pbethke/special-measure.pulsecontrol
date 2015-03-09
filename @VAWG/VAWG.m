classdef VAWG < handle
    properties (SetAccess = protected, GetAccess = public)
        awgs;
        
        %channel mapping
        % a cell array of arrays of 2 dimensional entries
        % [awgIndex hardwareChannel]
        % ex: [awgId hwdChnl] = virtualToHardware{0}{1}
        virtualToHardware = {};
        
        %trigger length in nanoseconds
        triggerLength = 4000;
    end

    methods
        add(self,groups);
            
        function zerolen = zero(self,grp,ind,zerolen)
            for awg = 1:length(self.awgs)
                zerolen = self.awgs(awg).zeroLength(grp,ind,zerolen);
            end    

        end
        
        function index = addAWG(self,awg)
            if ~isa(awg,'AWG')
                error('Object is no AWG.');
            else
                if ~isempty(self.awgs)
                    if find( strcmp({self.awgs.identifier},awg.identifier) )
                        error('AWG with identifier %s already exists.',awg.identifier);
                    end
                end
                
                self.awgs = [self.awgs(:) awg];
                index = length(self.awgs);
            end
        end
        
        function removeAWG(self, awg)
            awgIndex = self.getIndex(awg);
            
            for virtualChannel = 1:length(self.virtualToHardware)
                todelete = [];
                for entry = 1:length( self.virtualToHardware{virtualChannel} )
                    if self.virtualToHardware{virtualChannel}{entry}(1) == awgIndex
                        todelete(end+1) = entry;
                    end
                end
                self.virtualToHardware{virtualChannel}(todelete) = [];
            end
            
            self.awgs(awgIndex) = [];
        end
        
        function index = getIndex(self,awg)
            if isa(awg,'AWG')
                index = find( eq(awg,self.awgs) );
            elseif ischar(awg)
                index = find( strcmp({self.awgs.identifier},awg) );
            elseif isinteger(awg) || isfloat(awg)
                index = awg;
            else
                error('Recieved an invalid type to determine index.');
            end
            
            if length(self.awgs)<index
                error('Index %i to large. VAWG only knows %i AWGs.',index,length(self.awgs));
            end
        end
        
        function createVirtualChannel(self, awg, hardwareChannel, virtualChannel)
            awgIndex = self.getIndex(awg);
            
            awg = self.awgs(awgIndex);
            
            if hardwareChannel > awg.nChannels
                error('AWG %s only has %i hardware channels. Requested was %i', awg.identifier, awg.nChannels, hardwareChannel);
            end
            
            if size(self.virtualToHardware,2) < virtualChannel
                self.virtualToHardware{virtualChannel}{1} = [awgIndex hardwareChannel];
            else
                self.virtualToHardware{virtualChannel}{end+1} = [awgIndex hardwareChannel];
            end
        end
        
        function removeVirtualChannel(self, virtualChannel)
            if size(self.virtualToHardware,2) < virtualChannel || isempty(self.virtualToHardware{virtualChannel})
                return;
            end
            self.virtualToHardware{virtualChannel} = {};
        end
        
        function removeVirtualChannelMapping(self, awg, hardwareChannel, virtualChannel)
            awgIndex = getIndex(awg);
            if size(self.virtualToHardware,2) < virtualChannel || isempty(self.virtualToHardware{virtualChannel})
                return;
            end

            self.virtualToHardware{virtualChannel} = ...
                self.removeFromCellArray(self.virtualToHardware{virtualChannel}, [awgIndex hardwareChannel]);
        end
        
        function setActivePulseGroup(self,groupName)
            for awg = self.awgs
                awg.setActivePulseGroup(groupName);
            end
        end
        
        function arm(self)
            for awg = self.awgs
                awg.arm();
            end
        end
        
        function val = isPlaybackInProgress(self)
            activePlaybacks = zeros(1,length(self.awgs));
            for awg = 1:length(self.awgs)
                activePlaybacks(awg) = self.awgs(awg).isPlaybackInProgress();
            end
            
            val = sum(activePlaybacks)>0;
            
            if sum(activePlaybacks) ~= 0 && sum(activePlaybacks) ~= length(self.awgs)
                warning('One AWGs is still playing while another one has finished!');
            end
        end
        
        function setTriggerLength(self,triglen)
            self.triggerLength = triglen;
        end
        function triglen = getTriggerLength(self)
            triglen = self.triggerLength;
        end
    end
    
    methods (Static)
        
        function newArray = removeFromCellArray(array, value)
            newArray = array;
            
            todelete = [];
            for i = 1:size(newArray, 2);
                compare = array{i} == value;
                if (sum(compare==0) == 0)
                    todelete(end + 1) = i;
                end
            end
            
            newArray(todelete) = [];
        end
        
    end
end