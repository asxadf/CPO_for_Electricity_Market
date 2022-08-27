clc;
clear;
close all;
%% ------------------------------ Setting ------------------------------ %%
Day_Dispatch = 362;
NH = 14;
%
%% ------------------------------- Path -------------------------------- %%
Ini_Path = which('Location_CPO_v7.m');
Ini_Size = size('Location_CPO_v7.m', 2);
Link = Ini_Path(end - Ini_Size);
Path_Data = strcat(Ini_Path(1:end - Ini_Size - 1), Link, 'Database');
Path_Temp = strcat(Ini_Path(1:end - Ini_Size - 1), Link, 'Temp');
Date_All_List = importdata(strcat(Path_Data, Link, 'Date_All_List','.mat'));
Date_Dispatch = Date_All_List(Day_Dispatch);
%
%% ------------------------------ Loading ------------------------------ %%
[Day_Tra_All, Date_Tra_All] = Find_NT(NH, Link, Path_Data);
%
[Num_Gen,...
 Num_Branch,...
 Num_Bus,...
 Num_City,...
 Num_Hour,...
 Num_RES,...
 Gen_Capacity,...
 Gen_Price,...
 Branch,...
 Load_Gro_SUM_All_ACT,...
 Load_Gro_SUM_All_DAF,...
 Load_Gro_SUM_Dis_ACT,...
 Load_Gro_SUM_Dis_DAF, Load_Gro_SUM_Dis_DAF_UB, Load_Gro_SUM_Dis_DAF_LB,...
 Load_Net_SUM_All_ACT,...
 Load_Net_SUM_All_DAF,...
 Load_Net_SUM_Dis_ACT,...
 Load_Net_SUM_Dis_DAF,...
 Load_City_All_ACT,...
 Load_City_All_DAF,...
 Load_City_Dis_ACT,...
 Load_City_Dis_DAF,...
 RES_SUM_All_ACT,...
 RES_SUM_All_DAF, RES_SUM_All_DAF_UB, RES_SUM_All_DAF_LB,...
 RES_SUM_Dis_ACT,...
 RES_SUM_Dis_DAF, RES_SUM_Dis_DAF_UB, RES_SUM_Dis_DAF_LB,...
 RES_Farm_All_ACT,...
 RES_Farm_All_DAF, RES_Farm_All_DAF_UB, RES_Farm_All_DAF_LB,...
 RES_Farm_Dis_ACT,...
 RES_Farm_Dis_DAF, RES_Farm_Dis_DAF_UB, RES_Farm_Dis_DAF_LB,...
 R_Sys_Req_All,...
 R_Sys_Req_Dis,...
 R_H_Req_All,...
 R_H_Req_Dis,...
 R_C_Req_All,...
 R_C_Req_Dis,...
 PTDF_Gen,...
 PTDF_City,...
 PTDF_RES,...
 GS_Price,...
 LS_Price,...
 BS_Price,...
 Date_All_List,...
 Day, Pre_W_UB, Pre_W_LB,...
 Unit_Quick,...
 Unit_Thermal] = Database_CPO_v7(Date_Dispatch, Link, Path_Data);

Load_Net_SUM_Dis_AE = Load_Net_SUM_Dis_ACT - Load_Net_SUM_Dis_DAF;
Load_Net_SUM_All_AE = Load_Net_SUM_All_ACT - Load_Net_SUM_All_DAF;

Load_Gro_SUM_Dis_AE = Load_Gro_SUM_Dis_ACT - Load_Gro_SUM_Dis_DAF;
Load_Gro_SUM_All_AE = Load_Gro_SUM_All_ACT - Load_Gro_SUM_All_DAF;

RES_SUM_Dis_AE = RES_SUM_Dis_ACT - RES_SUM_Dis_DAF;
RES_SUM_All_AE = RES_SUM_All_ACT - RES_SUM_All_DAF;

for d = 1:366
    RES_Farm_All_AE{d} = RES_Farm_All_ACT{d} - RES_Farm_All_DAF{d};
end

for t = 1:24
    Load_Net_SUM_All_ME(t,1) = mean(Load_Net_SUM_All_AE(t, :));
    Load_Gro_SUM_All_ME(t,1) = mean(Load_Gro_SUM_All_AE(t, :));
    RES_SUM_All_ME(t,1)      = mean(RES_SUM_All_AE(t, :));
end

Load_Gro_SUM_All_DAF_Peak = max(Load_Gro_SUM_All_DAF);
Load_Gro_SUM_All_ACT_Peak = max(Load_Gro_SUM_All_ACT);
Load_Gro_SUM_All_DAF_Valley = min(Load_Gro_SUM_All_DAF);
Load_Gro_SUM_All_ACT_Valley = min(Load_Gro_SUM_All_ACT);

Load_Net_SUM_All_DAF_Peak = max(Load_Net_SUM_All_DAF);
Load_Net_SUM_All_ACT_Peak = max(Load_Net_SUM_All_ACT);
Load_Net_SUM_All_DAF_Valley = min(Load_Net_SUM_All_DAF);
Load_Net_SUM_All_ACT_Valley = min(Load_Net_SUM_All_ACT);

A(1) = find(Load_Gro_SUM_All_DAF_Peak == max(Load_Gro_SUM_All_DAF_Peak(245:335)));
A(2) = find(Load_Gro_SUM_All_ACT_Peak == max(Load_Gro_SUM_All_ACT_Peak(245:335)));
A(3) = find(Load_Net_SUM_All_DAF_Peak == max(Load_Net_SUM_All_DAF_Peak(245:335)));
A(4) = find(Load_Net_SUM_All_ACT_Peak == max(Load_Net_SUM_All_ACT_Peak(245:335)));

B(1) = find(Load_Gro_SUM_All_DAF_Valley == min(Load_Gro_SUM_All_DAF_Valley(245:335)));
B(2) = find(Load_Gro_SUM_All_ACT_Valley == min(Load_Gro_SUM_All_ACT_Valley(245:335)));
B(3) = find(Load_Net_SUM_All_DAF_Valley == min(Load_Net_SUM_All_DAF_Valley(245:335)));
B(4) = find(Load_Net_SUM_All_ACT_Valley == min(Load_Net_SUM_All_ACT_Valley(245:335)));