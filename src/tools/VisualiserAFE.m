% Simple class to visualise AFE features
% NM 21/09/2016

classdef VisualiserAFE < handle
    
    properties (SetAccess = private)
        drawHandle;         % draw handles
        updateTime = 0.5;   % update every updateTime seconds
        
        hLeftEar;
        hRightEar;
        hItd;
        hIld;
        sigmax = 1E-9;
    end
    
    methods
        
        function obj = VisualiserAFE(drawHandle)
            obj.drawHandle = drawHandle;
        end
        
        function reset(obj)

            obj.sigmax = 1E-9;
            
            % Left ear signal
            subplot(2,2,3,'Parent',obj.drawHandle);
            obj.hLeftEar = plot(0, 'Color', [0 .447 .741]);
            axis tight; ylim([-1 1]);
            %xlabel('Time (s)', 'FontSize', 14);
            set(gca,'XTick', [], 'XTickLabel',{});
            title('Left ear signal', 'FontSize', 14);
                
            % Right ear signal
            subplot(2,2,4,'Parent',obj.drawHandle);
            obj.hRightEar = plot(0, 'Color', [0 .447 .741]);
            axis tight; ylim([-1 1]);
            %xlabel('Time (s)', 'FontSize', 14);
            set(gca,'XTick', [], 'XTickLabel',{});
            title('Right ear signal', 'FontSize', 14);
            
            subplot(2,2,1,'Parent',obj.drawHandle);
            obj.hItd = imagesc([]);
            set(gca, 'YDir','normal', ...
                     'xlimmode','manual',...
                     'ylimmode','manual',...
                     'zlimmode','manual',...
                     'climmode','manual',...
                     'alimmode','manual');
            axis tight; ylim([-1 1]);
            ylabel('Lag (ms)', 'FontSize', 14);
            set(gca,'XTick', [], 'XTickLabel',{});
            title('Interaural time difference', 'FontSize', 14);
            
            % Plot ILD
            subplot(2,2,2,'Parent',obj.drawHandle);
            obj.hIld = plot(10,'.');
            axis tight; ylim([-10 10]);
            ylabel('ILD (dB)', 'FontSize', 14);
            set(gca,'XTick', [], 'XTickLabel',{});
            set(gca,'YTick',-10:5:10, 'YTickLabel',{'-10','-5','0','5','10'});
            title('Interaural level difference', 'FontSize', 14);
        end
        
        function draw(obj, data, timeStamp)
            
            sigLen = obj.updateTime * 2;
            
            % Plot ear signals
            if isprop(data, 'time')
                sig = [data.time{1}.Data(:) data.time{2}.Data(:)];
                fsHz = data.time{1}.FsHz;
                nSamples = floor(sigLen * fsHz);
                if size(sig,1) < nSamples
                    sigLen = obj.updateTime;
                    nSamples = sigLen * fsHz;
                end
                
                x = (1:nSamples) ./ fsHz + (timeStamp-sigLen);
                sig = sig(end-nSamples+1:end,:);
                m = max(abs(sig(:)));
                if m > obj.sigmax
                    obj.sigmax = m;
                end
                sig = sig ./ obj.sigmax;
                
                % Left ear
                set(obj.hLeftEar, 'xdata', x, 'ydata', sig(:,1));

                % Right ear signal
                set(obj.hRightEar, 'xdata', x, 'ydata', sig(:,2));
            end
            
            % Plot ITD
            if isprop(data, 'crosscorrelation')
                scorr = squeeze(mean(data.crosscorrelation{1}.Data(:),2));
                fsHz = data.crosscorrelation{1}.FsHz;
                nSamples = floor(sigLen * fsHz);
                if nSamples > size(scorr,1)
                    nSamples = size(scorr,1);
                end
                x = (1:nSamples) ./ fsHz + (timeStamp-sigLen);
                y = 1000.*data.crosscorrelation{1}.lags;
                scorr = scorr(end-nSamples+1:end, :)';
                set(obj.hItd, 'xdata', [x(1) x(end)], 'ydata', [y(1) y(end)], 'cdata', scorr);
            end
            
            % Plot ILD
            if isprop(data, 'ild')
                ild = mean(data.ild{1}.Data(:), 2);
                fsHz = data.ild{1}.FsHz;
                nSamples = floor(sigLen * fsHz);
                if nSamples > length(ild)
                    nSamples = length(ild);
                end
                ild = ild(end-nSamples+1:end);
                x = (1:nSamples) ./ fsHz + (timeStamp-sigLen);
                set(obj.hIld, 'xdata', x, 'ydata', ild);
            end
            drawnow;
        end
        
    end
end
