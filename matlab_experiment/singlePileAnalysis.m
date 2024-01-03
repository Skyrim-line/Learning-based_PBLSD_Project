classdef singlePileAnalysis
    %��׮���ݷ���
    %   �˴���ʾ��ϸ˵��
    
    properties
        filename %�ļ�λ�ü�����
        wave %����
        time %ʱ��
        tTop %׮������ʱ��
        tBottom %׮�ײ���ʱ��
        tBottomBd1 %׮�ײ���ʱ��߽�1
        tBottomBd2 %׮�ײ���ʱ��߽�2
        cementNo %׮���ʣ�ˮ���
        vmin %��С����
        vmax %�����
        vMeasure %��������
        pileLength %׮����
        peakTime %׮�ڲ���ʱ�� ����
        peakAmplitude % ׮�ڲ����������һ����
        bottomAmplitude % ׮�ײ����������һ����
        Ecode=0; % -1 û���ҵ�׮���ź�
        
    end
    
    methods
        function obj = singlePileAnalysis(filename,pileLength,dt,vmin,vmax,cNo)
            % ��Ӳ���ж�ȡfilename��Ӧ�Ĳ����ļ�
            %   �˴���ʾ��ϸ˵��
            % ����ж����¼����ȡ���һ����¼
            load(filename)
            obj.wave=drsl(:,end);
            obj.pileLength=pileLength;
            obj.time=(1:length(obj.wave))'*dt; %��λ�Ǧ�s
            obj.filename=filename;
            obj.vmin=vmin;
            obj.vmax=vmax;
            obj.cementNo=cNo;
            
            obj = preprocess(obj);
            % ׮���źŷ���
            obj=pileBottomSignalAnalysis(obj);
            
            %׮���źŷ���
            if obj.Ecode==0
                obj=signalInPileAnalysis(obj);
            end
        end
        
        function obj = preprocess(obj)
            %preprocess �˴���ʾ�йش˷�����ժҪ
            % ����Ԥ����
            %   �˴���ʾ��ϸ˵��
            % �жϼ����Ƿ���������������-1
            % ǰ200�������ڵ�������������Ǹ��ģ�˵��������,��һ��ʱ�����Զ�У������
            data=abs(obj.wave(1:200));
            [~,index]=max(data);
            % ���ָ�����������������������
            % �����ж����������������ǰ����һ���������Ϊ������20%���ϵķ�
            % �� �����Ϊ ׮���ź� �����������й�һ��
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
            %׮���źŷ���
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
            %׮���źŷ���
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
                %������׮��
                disp('������׮��');
                
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
                    %û�з���׮���ź�
                    disp('û�з���׮���ź�')
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
            %���Ʋ�������
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
            
            %����׮���ź�
            if ~isempty(obj.bottomAmplitude)
                plot(ax,[obj.tBottom,obj.tBottom]/1e3,[0 obj.bottomAmplitude],'m');
                plot(ax,[obj.tBottomBd1,obj.tBottomBd1]/1e3,[0 obj.bottomAmplitude],'m--');
                plot(ax,[obj.tBottomBd2,obj.tBottomBd2]/1e3,[0 obj.bottomAmplitude],'m--');
                text(ax,obj.tBottom/1e3,(obj.bottomAmplitude+(1-obj.bottomAmplitude)/4),strcat('��������',num2str(round(obj.vMeasure)),'m/s'),'HorizontalAlignment','center')
            end
            
            %����׮���ź�
            if ~isempty(obj.peakAmplitude)
                plot(ax,[obj.peakTime obj.peakTime]'/1e3,[obj.peakAmplitude*0 obj.peakAmplitude]','r');
                
            end
            
        end
        function plotShift(obj,shift,ax)
            %���Ʋ�������
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
            
            %����׮���ź�
            if ~isempty(obj.bottomAmplitude)
                plot(ax,[obj.tBottom,obj.tBottom]/1e3,[0 1]+shift,'m');
                plot(ax,[obj.tBottomBd1,obj.tBottomBd1]/1e3,[0 1]+shift,'m--');
                plot(ax,[obj.tBottomBd2,obj.tBottomBd2]/1e3,[0 1]+shift,'m--');
                text(ax,obj.tBottom/1e3,(obj.bottomAmplitude+(1-obj.bottomAmplitude)/4)+shift,strcat('��������',num2str(round(obj.vMeasure)),'km/s'),'HorizontalAlignment','center')
            end
            
            %����׮���ź�
            if ~isempty(obj.peakAmplitude)
                plot(ax,[obj.peakTime obj.peakTime]'/1e3,[obj.peakAmplitude*0 obj.peakAmplitude]'+shift,'r');
                
            end
            
        end
    end
end

