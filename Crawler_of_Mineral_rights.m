clc;
clear;
close all;
options = weboptions('Timeout',Inf);
waitforget = {'dq-24','dq-25','dq-27','dq-31'};
province01 = {'贵州省','云南省','陕西省','新疆维吾尔自治区'};
%for z = 1:10
z = 3;
setpro = waitforget{1,z};
fprintf('开始：%s\n',setpro);
getpages = webread(sprintf(['http://kyqgs.mnr.gov.cn/search_projects_sx.jspx?times=sj-2&kuangquans=kq-2&areas=',setpro]),options);
[~,pages0] = (regexpi(getpages,'<input   type="button" value="1" style="cursor:pointer;background-color: #1F82D2!important;color:#ffffff;border-top:0px solid #E2E2E2;border-bottom:0px solid #E2E2E2;border-left:0px solid #E2E2E2;border-right:0px solid #E2E2E2;" onclick="_gotoPage(\S*);" />','match','tokens'));
temppages0 = regexp(pages0{1,1}{1,1},',','split');
temppages0{1,1}(1) = [];
pages = str2double(temppages0{1,1});
province = cell(pages*10,1);%发证机关
name = cell(pages*10,1);%矿权名称
owner = cell(pages*10,1);%所有人
type = cell(pages*10,1);%矿种
starttime = cell(pages*10,1);%起始日期
endtime = cell(pages*10,1);%终止日期
period = cell(pages*10,1);%出让年限（年）
updatetime = cell(pages*10,1);%最近更新日期
remain = cell(pages*10,1);%剩余时间（月）
scale = cell(pages*10,1);%规模
isdoing = cell(pages*10,1);%是否在产
xx = cell(pages*10,1);%x坐标
yy = cell(pages*10,1);%y坐标
amaplocation = cell(pages*10,1);
amapprovince = cell(pages*10,1);
amapcity = cell(pages*10,1);
amapcounty = cell(pages*10,1);%高德地图API
index = 1;
errorfatherpage = cell(pages*10,1);
errorpages = cell(pages*10,1);
for i = 1:1:pages
    try
        data = webread(sprintf(['http://kyqgs.mnr.gov.cn/search_projects_sx.jspx?pageNo=',char(num2str(i)),'&firstListTotalCount=&secondListTotalCount=&thirdListTotalCount=&fourthListTotalCount=&times=sj-2&kuangquans=kq-2&areas=',setpro]),options);
    catch
        errorfatherpage{index} = char(num2str(i));
        continue;
    end
    k = strfind(data,'<a style="color: #1F82D2;font-size: 14px;text-decoration: underline;" href="');
    for j = 1:length(k)
        link = string(data(k(j)+76:1:k(j)+76+67));
        try
            datatemp = webread(sprintf(['http://kyqgs.mnr.gov.cn',char(link)]),options);
        catch
            errorpages{index} = char(link);
            continue;
        end
        [~,type0] = (regexpi(datatemp,'<td class="title_back_right_bt" style="width: 15%">开采矿种：</td>\n						<td class="title_back_left" style="width: 35%"  >(\S*)</td>','match','tokens'));
        if(~isempty(type0) && contains(type0{1}{1},'建筑'))
            [~,province0] = (regexpi(datatemp,'<td class="title_back_right_bt" style="width: 15%">发证机关：</td>\n						<td class="title_back_left" style="width: 35%"  >(\S*)</td>','match','tokens'));
            [~,name0] = (regexpi(datatemp,'<td colspan="1" class="title_back_right_bt" style="width: 15%">矿山名称：</td>\n						<td colspan="3" class="title_back_left" style="width: 35%"  >([^\n\f\r]*)</td>','match','tokens'));
            [~,owner0] = (regexpi(datatemp,'<td colspan="1" class="title_back_right_bt" style="width: 15%">采矿权人：</td>\n						<td colspan="3" class="title_back_left" style="width: 35%"  >([^\n\f\r]*)</td>','match','tokens'));
            province0 = province0{1}{1};
            if(isempty(province0))
                province0 = '未知';
            end
            name0 = name0{1}{1};
            owner0 = owner0{1}{1};
            type0 = type0{1}{1};
            gettimetemp = strfind(datatemp,'<td class="title_back_right_bt" style="width: 15%">有效期限：</td>');
            start00 = strsplit(datatemp(gettimetemp+135:gettimetemp+144),'-');
            end00 = strsplit(datatemp(gettimetemp+183:gettimetemp+192),'-');
            startyear = str2double(start00{1});startmonth = str2double(start00{2});startday = str2double(start00{3});
            endyear = str2double(end00{1});endmonth = str2double(end00{2});endday = str2double(end00{3});
            period0 = num2str(roundn((endyear-startyear)+((endmonth-startmonth)/12)++((endday-startday)/365),-2));
            start0 = [start00{1},'/',start00{2},'/',start00{3}];
            end0 = [end00{1},'/',end00{2},'/',end00{3}];
            updatenow = strsplit(char(datetime('today')),'-');
            updateyear = str2double(updatenow{1});updatemonth = str2double(updatenow{2});updateday = str2double(updatenow{3});
            updatetime0 = [updatenow{1},'/',updatenow{2},'/',updatenow{3}];
            if((endyear-updateyear)*12+(endmonth-updatemonth) < 0)
                remain0 = '已到期';
            else
                remain0 = num2str(roundn((endyear-updateyear)*12+(endmonth-updatemonth),-2));
            end
            isstate = regexpi(datatemp,'<td class="title_back_right_bt" >生产状态：</td>','match');
            if (isempty(isstate))
                isdoing0 = '生产';
            else
                kk = strfind(datatemp,'<td class="title_back_right_bt" >生产状态：</td>');
                isdoing0 = datatemp(kk+92:kk+93);
            end
            [~,scale00] = (regexpi(datatemp,'<td class="title_back_right_bt" >设计（核定）矿山规模：</td>\n						<td class="title_back_left" colspan="2" > (\S*)</td>','match','tokens'));
            [~,scale01] = (regexpi(datatemp,'<td class="title_back_right_bt" >设计矿山（核定）规模（）：</td>\n						<td class="title_back_left" colspan="2" > (\S*)</td>','match','tokens'));
            [~,scale02] = (regexpi(datatemp,'<td class="title_back_right_bt" >设计矿山（核定）规模（万立方米/年）：</td>\n						<td class="title_back_left" colspan="2" > (\S*)</td>','match','tokens'));
            [~,scale03] = (regexpi(datatemp,'<td class="title_back_right_bt" >设计矿山（核定）规模（万吨/年）：</td>\n						<td class="title_back_left" colspan="2" > (\S*)</td>','match','tokens'));
            [~,scale04] = (regexpi(datatemp,'<td class="title_back_right_bt" >设计矿山（核定）规模（吨/年）：</td>\n						<td class="title_back_left" colspan="2" > (\S*)</td>','match','tokens'));
            scale0 = {scale00;scale01;scale02;scale03;scale04};
            scale0(cellfun(@isempty,scale0))=[];
            if (isempty(scale02))
                scale0 = char(num2str(str2double(scale0{1}{1}{1})));
            else
                scale0 = char(num2str(str2double(scale0{1}{1}{1})*2.6));
            end
            [~,xy] = (regexpi(datatemp,'var strPoints = (\S*);','match','tokens'));
            xy = xy{1,1}{1,1};
            xy(1) = [];
            xy(end) = [];
            xys = (regexp(xy,';','split'))';
            xys(cellfun(@isempty,xys))=[];
            xyget = zeros(length(xys),4);
            for iii = 1:length(xys)
                tempxy = regexp(xys{iii,1},',','split');
                xyget(iii,1) = str2double(tempxy{1,1});
                xyget(iii,2) = str2double(tempxy{1,2});
                xyget(iii,3) = str2double(tempxy{1,3});
                xyget(iii,4) = str2double(tempxy{1,4});
            end
            numone = find(xyget(:,2) == 1);
            [lenxyget,~] = size(xyget);
            numone = [numone;lenxyget+1];
            xtemp = num2str([]);
            ytemp = num2str([]);
            for jjj = 1:length(numone)-1
                xtemp1 = num2str([]);
                ytemp1 = num2str([]);
                for kkk = numone(jjj):numone(jjj+1)-1
                    xtemp1 = strcat(xtemp1,',',num2str(xyget(kkk,3)));
                    ytemp1 = strcat(ytemp1,',',num2str(xyget(kkk,4)));
                end
                xtemp1(1) = [];
                ytemp1(1) = [];
                xtemp1 = strcat('[',xtemp1,']');
                ytemp1 = strcat('[',ytemp1,']');
                xtemp = strcat(xtemp,',',xtemp1);
                ytemp = strcat(ytemp,',',ytemp1);
            end
            xtemp(1) = [];
            ytemp(1) = [];
            try
                location = webread(sprintf(['http://restapi.amap.com/v3/geocode/regeo?location=',num2str(mean(xyget(:,3))),',',num2str(mean(xyget(:,4))),'&key=17479d86c0c6a0305024e1142351a0a4']),options);
            catch
                try
                    location = webread(sprintf(['http://restapi.amap.com/v3/geocode/regeo?location=',num2str(mean(xyget(:,3))),',',num2str(mean(xyget(:,4))),'&key=17479d86c0c6a0305024e1142351a0a4']),options);
                catch
                    location = webread(sprintf(['http://restapi.amap.com/v3/geocode/regeo?location=',num2str(mean(xyget(:,3))),',',num2str(mean(xyget(:,4))),'&key=17479d86c0c6a0305024e1142351a0a4']),options);
                end
            end
            amapprovince0 = province01{1,z};
            amapcity0 = location.regeocode.addressComponent.city;
            if(isempty(amapcity0))
                amapcity0 = amapprovince0;
            end
            amapcounty0 = location.regeocode.addressComponent.district;
            if(isempty(amapcounty0))
                amapcounty0 = amapcity0;
            end
            amaplocation0 = location.regeocode.formatted_address;
            province{index} = province0;
            name{index} = name0;
            owner{index} = owner0;
            type{index} = type0;
            starttime{index} = start0;
            endtime{index} = end0;
            period{index} = period0;
            updatetime{index} = updatetime0;
            remain{index} = remain0;
            scale{index} = scale0;
            isdoing{index} = isdoing0;
            xx{index} = xtemp;
            yy{index} = ytemp;
            amaplocation{index} = amaplocation0;
            amapprovince{index} = amapprovince0;
            amapcity{index} = amapcity0;
            amapcounty{index} = amapcounty0;
            index = index+1;
            fprintf('省：%s | 市：%s | 县：%s\n',amapprovince0,amapcity0,amapcounty0);
            fprintf('矿名：%s\n',name0);
            fprintf('类型：%s\n',type0);
        end
        fprintf('已完成第%d页第%d个矿权的资料采集，共%d页\n',i,j,pages);
    end
end
title = {'序号','省','市','县','所在地区','矿权名称','所有人','发证机关','矿种','起始日期','终止日期','出让年限（年）','最近更新日期','剩余时间（月）','设计矿山（核定）规模（万吨/年）','是否在产','经度坐标','纬度坐标'};
name(cellfun(@isempty,name))=[];
savenum = length(name);
province(savenum+1:end)=[];
owner(savenum+1:end)=[];
type(savenum+1:end)=[];
starttime(savenum+1:end)=[];
endtime(savenum+1:end)=[];
period(savenum+1:end)=[];
updatetime(savenum+1:end)=[];
remain(savenum+1:end)=[];
scale(savenum+1:end)=[];
errorpages(cellfun(@isempty,errorpages))=[];
errorfatherpage(cellfun(@isempty,errorfatherpage))=[];
isdoing(savenum+1:end)=[];
xx(savenum+1:end)=[];
yy(savenum+1:end)=[];
amaplocation(savenum+1:end)=[];
amapprovince(savenum+1:end)=[];
amapcity(savenum+1:end)=[];
amapcounty(savenum+1:end)=[];
order = num2cell(1:1:length(province))';
exceldata = cell(length(province)+1,18);
exceldata(1,:) = title;
exceldata(2:end,1) = order;
exceldata(2:end,2) = amapprovince;
exceldata(2:end,3) = amapcity;
exceldata(2:end,4) = amapcounty;
exceldata(2:end,5) = amaplocation;
exceldata(2:end,6) = name;
exceldata(2:end,7) = owner;
exceldata(2:end,8) = province;
exceldata(2:end,9) = type;
exceldata(2:end,10) = starttime;
exceldata(2:end,11) = endtime;
exceldata(2:end,12) = period;
exceldata(2:end,13) = updatetime;
exceldata(2:end,14) = remain;
exceldata(2:end,15) = scale;
exceldata(2:end,16) = isdoing;
exceldata(2:end,17) = xx;
exceldata(2:end,18) = yy;
errordata = cell(length(errorpages)+length(errorfatherpage)+2,1);
errordata(1,1) = {'不能访问的父页面的页码：'};
errordata(2:length(errorfatherpage)+2-1,1) = errorfatherpage;
errordata(length(errorfatherpage)+2,1) = {'不能访问的子页面的网址ID：'};
errordata(length(errorfatherpage)+3:end,1) = errorpages;
namexls = ['C:\Users\Folmo\Desktop\Crawler_of_Mineral_rights_',setpro,'.xlsx'];
xlswrite(namexls,exceldata);
nameerror = ['C:\Users\Folmo\Desktop\errorpages_',setpro,'.xlsx'];
xlswrite(nameerror,errordata);
%end
