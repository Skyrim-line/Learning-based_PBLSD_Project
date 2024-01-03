% a=readtable('文件路径表汇总-gecan.xlsx');
a=readtable('最新修改好的路径表.xlsx');
allData=a(:,1:6);
allData.Properties.VariableNames={'place','path','pid','pl','cnum','dt'};
size(allData,1)
for i=size(allData,1):-1:1
    if strcmp(allData{i,1},'') | strcmp(allData{i,1},'工地') | isnan(allData{i,4}) | length(allData{i,6}{1})==0
        allData(i,:)=[];
    end
end
size(allData,1)


dt=zeros(size(allData,1),1);
for i=size(allData,1):-1:1
    tmp=allData{i,6}{1};
    tmp=tmp(1:end-2);
    if length(tmp)==0
        i
    else
    dt(i)=str2num(tmp);
    end
end
allData=allData(:,1:5);
allData(:,6)=table(dt);
allData.Properties.VariableNames={'place','path','pid','pl','cnum','dt'};

% save('allData','allData')