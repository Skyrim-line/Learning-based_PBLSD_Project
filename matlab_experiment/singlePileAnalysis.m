classdef singlePileAnalysis
    %单桩数据分析
    %   此处显示详细说明
    
    properties
        filename %文件位置及名称
        wave %波形
        time %时间
        tTop %桩顶波峰时间
        tBottom %桩底波峰时间
        tBottomBd1 %桩底波峰时间边界1
        tBottomBd2 %桩底波峰时间边界2
        cementNo %桩材质，水泥号
        vmin %最小波速
        vmax %最大波速
        vMeasure %测量波速
        pileLength %桩长度
        peakTime %桩内波峰时间 数组
        peakAmplitude % 桩内波峰振幅（归一化后）
        bottomAmplitude % 桩底波峰振幅（归一化后）
        Ecode=0; % -1 没有找到桩底信号
        
    end
    
    methods
        function obj = singlePileAnalysis(filename,pileLength,dt,vmin,vmax,cNo)
            % 从硬盘中读取filename对应的波形文件
            %   此处显示详细说明
            % 如果有多道记录，读取最后一道记录
            load(filename)
            obj.wave=drsl(:,end);
            obj.pileLength=pileLength;
            obj.time=(1:length(obj.wave))'*dt; %单位是μs
            obj.filename=filename;
            obj.vmin=vmin;
            obj.vmax=vmax;
            obj.cementNo=cNo;
            
            obj = preprocess(obj);
            % 桩底信号分析
            obj=pileBottomSignalAnalysis(obj);
            
            %桩内信号分析
            if obj.Ecode==0
                obj=signalInPileAnalysis(obj);
            end
        end
        
        function obj = preprocess(obj)
            %preprocess 此处显示有关此方法的摘要
            % 数据预处理
            %   此处显示详细说明
            % 判断极性是否反向，如果反向则乘以-1
            % 前200个数据内的最大振幅的如果是负的，说明反向了,归一化时可以自动校正极性
            data=abs(obj.wave(1:200));
            [~,index]=max(data);
            % 出现负向振幅比正向振幅还大的情况
            % 增加判断条件，如果最大振幅前还有一个相对增幅为最大振幅20%以上的峰
            % 则 这个峰为 桩顶信号 以这个振幅进行归一化
            tTop=obj.time(index);
            wave=abs(obj.wave(index));
            tmpwave=obj.wave(obj.time<tTop);
            [pks,loc]=findpeaks(abs(tmpwave));
            loc=loc(abs(pks)>0.2*wave);
            pks=pks(abs(pks)>0.2*wave);
            
            if isempty(pks)
               
                obj.tTop=tTop;
                obj.wave=obj.wave/obj.wave(index); 
            else
                loc=loc(1);
                obj.tTop=obj.time(loc);
                pks=pks(1);
                obj.wave=obj.wave/obj.wave(loc);
            end
            
        end
        function obj=signalInPileAnalysis(obj)
            %桩内信号分析
            index=obj.time>obj.tTop & obj.time<obj.tBottom;
            Iwave=obj.wave(index);
            Itime=obj.time(index);
            [pks,loc]=findpeaks(Iwave);
            loc=loc(pks>0);
            pks=pks(pks>0);
            if ~isempty(loc)
                obj.peakTime=Itime(loc);
                obj.peakAmplitude=pks;
            end
        end
        
        function obj=pileBottomSignalAnalysis(obj)
            %桩底信号分析
            if isempty(obj.vmin)
                vmin=3500;
            else
                vmin=obj.vmin;
            end
            
            if isempty(obj.vmax)
                vmax=5800;
            else
                vmax=obj.vmax;
            end
            
            if isempty(obj.pileLength)
                %请输入桩长
                disp('请输入桩长');
                
            else
                pl=obj.pileLength;
                tmin=1e6*pl/vmax*2+obj.tTop;
                tmax=1e6*pl/vmin*2+obj.tTop;
                obj.tBottomBd1=tmin;
                obj.tBottomBd2=tmax;
                index=obj.time>tmin&obj.time<tmax;
                
                bwave=obj.wave(index);
                btime=obj.time(index);
                if isempty(bwave)
                    pks=[];
                else
                    [pks,loc] = findpeaks(bwave);
                end
                if isempty(pks)
                    %没有发现桩底信号
                    disp('没有发现桩底信号')
                    obj.Ecode=-1;
                else
                    [bAmp,bindex]=max(pks);
                    obj.bottomAmplitude=bAmp;
                    obj.tBottom=btime(loc(bindex));
                    obj.vMeasure=obj.pileLength*2/(obj.tBottom-obj.tTop)*1e6;
                end
            end
            
            
            
            
        end
        function plot(obj,ax)
            %绘制波形数据
            if nargin==1
                ax=gca;
            end
            
            plot(ax,obj.time/1e3,obj.wave)
            ax.NextPlot='add';
            plot(ax,obj.time/1e3,obj.time*0,'k--');
            plot(ax,[obj.tTop/1e3 obj.tTop/1e3],[0 1],'g');
            xlabel(ax,'time(ms)')
            ylabel(ax,'Relative Amplitude');
            axis(ax,[min(obj.time)/1e3,max(obj.time)/1e3,-0.4,1]);
            
            %绘制桩底信号
            if ~isempty(obj.bottomAmplitude)
                plot(ax,[obj.tBottom,obj.tBottom]/1e3,[0 obj.bottomAmplitude],'m');
                plot(ax,[obj.tBottomBd1,obj.tBottomBd1]/1e3,[0 obj.bottomAmplitude],'m--');
                plot(ax,[obj.tBottomBd2,obj.tBottomBd2]/1e3,[0 obj.bottomAmplitude],'m--');
                text(ax,obj.tBottom/1e3,(obj.bottomAmplitude+(1-obj.bottomAmplitude)/4),strcat('测量波速',num2str(round(obj.vMeasure)),'m/s'),'HorizontalAlignment','center')
            end
            
            %绘制桩内信号
            if ~isempty(obj.peakAmplitude)
                plot(ax,[obj.peakTime obj.peakTime]'/1e3,[obj.peakAmplitude*0 obj.peakAmplitude]','r');
                
            end
            
        end
        function plotShift(obj,shift,ax)
            %绘制波形数据
            if nargin==2
                ax=gca;
            end
            
            plot(ax,obj.time/1e3,shift+obj.wave,'b')
            ax.NextPlot='add';
            plot(ax,obj.time/1e3,obj.time*0+shift,'k--');
            plot(ax,obj.time/1e3,obj.time*0+shift+1,'k--');
            plot(ax,[obj.tTop/1e3 obj.tTop/1e3],shift+[0 1],'g');
            xlabel(ax,'time(ms)')
            ylabel(ax,'Relative Amplitude');
%             axis(ax,[min(obj.time)/1e3,max(obj.time)/1e3,-0.4,1]);
            
            %绘制桩底信号
            if ~isempty(obj.bottomAmplitude)
                plot(ax,[obj.tBottom,obj.tBottom]/1e3,[0 1]+shift,'m');
                plot(ax,[obj.tBottomBd1,obj.tBottomBd1]/1e3,[0 1]+shift,'m--');
                plot(ax,[obj.tBottomBd2,obj.tBottomBd2]/1e3,[0 1]+shift,'m--');
                text(ax,obj.tBottom/1e3,(obj.bottomAmplitude+(1-obj.bottomAmplitude)/4)+shift,strcat('测量波速',num2str(round(obj.vMeasure)),'km/s'),'HorizontalAlignment','center')
            end
            
            %绘制桩内信号
            if ~isempty(obj.peakAmplitude)
                plot(ax,[obj.peakTime obj.peakTime]'/1e3,[obj.peakAmplitude*0 obj.peakAmplitude]'+shift,'r');
                
            end
            
        end
    end
end

