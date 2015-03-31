classdef IOTestDriver < handle & matlab.mixin.Heterogeneous
    
    properties (SetAccess = private, GetAccess = private)
        configurationProvider;
        dac;
    end
    
    properties (SetAccess = private, GetAccess = public)
        expectedData = [];
        measuredData = [];
    end
    
    methods (Access = public)
        
        function obj = IOTestDriver(configurationProvider)
            if ~isa(configurationProvider, 'TestConfigurationProvider')
                error('IOTestDriver requires an instance of TestConfigurationProvider for parameter configurationProvider!');
            end
            obj.configurationProvider = configurationProvider;
        end
        
        function success = run(self)
            self.init();
            
            self.dac.issueTrigger();
            
            while self.vawg.playbackInProgress()
                pause(1);
                fprintf('Waiting for playback to finish...\n');
            end

            self.measuredData = self.dac.getResult(self.configurationProvider.inputChannel());
            
            success = self.evaluate();
        end
        
    end
    
    methods (Access = private)
        
        function init(self)
            
            % setup awg
            self.initVAWG();
                        
            % obtain pulse group and expected data from test configuration
            self.configurationProvider.createPulseGroup();
            pulseGroup = self.configurationProvider.getPulseGroup();
            self.expectedData = self.configurationProvider.getExpectedData();
            
            % obtain DAC instance from test configuration
            self.dac = self.configurationProvider.createDAC();
            self.dac.useAsTriggerSource();
            
            % arm vawg
            global vawg;
            vawg.add(pulseGroup);
            vawg.setActivePulseGroup(pulseGroup);
            vawg.arm();
        end
        
        function initVAWG(self)
            global vawg;
            
            vawg = VAWG();
            awg = PXDAC_DC('messrechnerDC', 1);
            awg.setOutputVoltage(1, 1);

            vawg.addAWG(awg);
            vawg.createVirtualChannel(awg, 1, 1);
        end
        
        function success = evaluate(self)
           err = self.measuredData - self.expectedData; % error signal
           rms = std(err,0); % average error per sample
           maxerr = max(abs(err)); % maximum single error
           satisfiesMeanThreshold = rms < self.configurationProvider.getMeanErrorThreshold();
           satisfiesSingleThreshold = maxerr < self.configurationProvider.getSingleErrorThreshold();
           success = satisfiesMeanThreshold && satisfiesSingleThreshold; 
        end
        
    end
    
end

