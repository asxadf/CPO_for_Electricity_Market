clc;
clear;
close all;
%% ------------------------------ Setting ------------------------------ %%
Case = 'CPO';
% 'CPO': Closed-Loop Predict-and-Optimize
% 'PPO': Pefect      Predict-then-Optimize
% 'OPO': Open-Loop   Predict-then-Optimize
%% ------------------------------- Path -------------------------------- %%
UC_Mode = Case(1);
Ini_Path = which('Location_CPO_v7.m');
Ini_Size = size('Location_CPO_v7.m', 2);
Link = Ini_Path(end - Ini_Size);
Path_Data = strcat(Ini_Path(1:end - Ini_Size - 1), Link, 'Database');
Path_Case = strcat(Ini_Path(1:end - Ini_Size - 1), Link, 'Case_Studies');
Path_Case = strcat(Path_Case, Link, Case);
Date_Dispatch_List = importdata(strcat(Path_Case, Link, 'Date_Dispatch_List.mat'));
Num_Day = size(Date_Dispatch_List, 1);
%
%% ---------------------------- Prepare Box ---------------------------- %%
% UC
Var_UC_I     = cell(Num_Day, 1);
Var_UC_I_SU  = cell(Num_Day, 1);
Var_UC_I_SD  = cell(Num_Day, 1);
Var_UC_I_RC  = cell(Num_Day, 1);
Var_UC_P     = cell(Num_Day, 1);
Var_UC_W     = cell(Num_Day, 1);
Var_UC_R_H   = cell(Num_Day, 1);
Var_UC_R_C   = cell(Num_Day, 1);

Cost_UC_SU   = zeros(Num_Day, 1);
Cost_UC_NL   = zeros(Num_Day, 1);
Cost_UC_P    = zeros(Num_Day, 1);
Cost_UC_RH   = zeros(Num_Day, 1);
Cost_UC_RC   = zeros(Num_Day, 1);
Cost_UC_ACT  = zeros(Num_Day, 1);
Cost_SYS_EXP = zeros(Num_Day, 1);

RES_Pre_Farm = cell(Num_Day, 1);
RES_Pre_SUM  = cell(Num_Day, 1);
R_H_Req_Dis  = cell(Num_Day, 1);
R_C_Req_Dis  = cell(Num_Day, 1);
% ED
Var_ED_I     = cell(Num_Day, 1);
Var_ED_I_SU  = cell(Num_Day, 1);
Var_ED_I_SD  = cell(Num_Day, 1);
Var_ED_P     = cell(Num_Day, 1);
Var_ED_W     = cell(Num_Day, 1);
Var_ED_S1    = cell(Num_Day, 1);
Var_ED_S2    = cell(Num_Day, 1);
Var_ED_S3    = cell(Num_Day, 1);
Var_ED_S4    = cell(Num_Day, 1);
Cost_ED_SU   = zeros(Num_Day, 1);
Cost_ED_NL   = zeros(Num_Day, 1);
Cost_ED_P    = zeros(Num_Day, 1);
Cost_ED_S1   = zeros(Num_Day, 1);
Cost_ED_S2   = zeros(Num_Day, 1);
Cost_ED_S3   = zeros(Num_Day, 1);
Cost_ED_S4   = zeros(Num_Day, 1);
Cost_ED_ACT  = zeros(Num_Day, 1);
Cost_SYS_ACT = zeros(Num_Day, 1);

Rate_RES   = cell(Num_Day, 1);
Rate_RH    = cell(Num_Day, 1);
Rate_RH_Up = cell(Num_Day, 1);
Rate_RH_Dn = cell(Num_Day, 1);
Rate_RC    = cell(Num_Day, 1);

Rate_RES_AVR   = zeros(Num_Day, 1);
Rate_RH_AVR    = zeros(Num_Day, 1);
Rate_RH_Up_AVR = zeros(Num_Day, 1);
Rate_RH_Dn_AVR = zeros(Num_Day, 1);
Rate_RC_AVR    = zeros(Num_Day, 1);

PE_MAE  = zeros(Num_Day, 1);
PE_MAPE = zeros(Num_Day, 1);
PE_MOPE = zeros(Num_Day, 1);
PE_MUPE = zeros(Num_Day, 1);

OVar_Phi_RES = cell(Num_Day, 1);
OVar_Phi_R_H = cell(Num_Day, 1);
OVar_Phi_R_C = cell(Num_Day, 1);
%
%% ------------------------------ Testing ------------------------------ %%
if UC_Mode == 'C'
    OVar_Phi_RES = importdata(strcat(Path_Case, Link, 'OVar_Phi_RES.mat'));
    OVar_Phi_R_H = importdata(strcat(Path_Case, Link, 'OVar_Phi_R_H.mat'));
    OVar_Phi_R_C = importdata(strcat(Path_Case, Link, 'OVar_Phi_R_C.mat'));
end
for Day = 1:Num_Day
        disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
        disp(['Day ', num2str(Day)]);
        disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
        %
        [Var_UC_I{Day},...
         Var_UC_I_SU{Day},...
         Var_UC_I_SD{Day},...
         Var_UC_I_RC{Day},...
         Var_UC_P{Day},...
         Var_UC_W{Day},...
         Var_UC_R_H{Day},...
         Var_UC_R_C{Day},...
         Cost_UC_SU(Day),...
         Cost_UC_NL(Day),...
         Cost_UC_P(Day),...
         Cost_UC_RH(Day),...
         Cost_UC_RC(Day),...
         Cost_UC_ACT(Day),...
         Cost_SYS_EXP(Day),...
         RES_Pre_Farm{Day},...
         RES_Pre_SUM{Day},...
         R_H_Req_Dis{Day},...
         R_C_Req_Dis{Day}]...
         = UC_Auto_v7(UC_Mode,...
                      Date_Dispatch_List(Day),...
                      round(OVar_Phi_RES{Day}, 2),...
                      round(OVar_Phi_R_H{Day}, 2),...
                      round(OVar_Phi_R_C{Day}, 2),...
                      Link,...
                      Path_Data);
         %
         [Var_ED_I{Day},...
          Var_ED_I_SU{Day},...
          Var_ED_I_SD{Day},...
          Var_ED_P{Day},...
          Var_ED_W{Day},...
          Var_ED_S1{Day},...
          Var_ED_S2{Day},...
          Var_ED_S3{Day},...
          Var_ED_S4{Day},...
          Cost_ED_SU(Day),...
          Cost_ED_NL(Day),...
          Cost_ED_P(Day),...
          Cost_ED_S1(Day),...
          Cost_ED_S2(Day),...
          Cost_ED_S3(Day),...
          Cost_ED_S4(Day),...
          Cost_ED_ACT(Day),...
          Cost_SYS_ACT(Day),...
          Rate_RES{Day},...
          Rate_RH{Day},...
          Rate_RH_Up{Day},...
          Rate_RH_Dn{Day},...
          Rate_RC{Day},...
          Rate_RES_AVR(Day),...
          Rate_RH_AVR(Day),...
          Rate_RH_Up_AVR(Day),...
          Rate_RH_Dn_AVR(Day),...
          Rate_RC_AVR(Day),...
          PE_MAE(Day),...
          PE_MAPE(Day),...
          PE_MOPE(Day),...
          PE_MUPE(Day)]...
          = ED_Auto_v7(Date_Dispatch_List(Day),...
                       Var_UC_I{Day},...
                       Var_UC_P{Day},...
                       Var_UC_R_H{Day},...
                       Var_UC_R_C{Day},...
                       Cost_UC_ACT(Day),...
                       RES_Pre_Farm{Day},...
                       RES_Pre_SUM{Day},...
                       R_H_Req_Dis{Day},...
                       R_C_Req_Dis{Day},...
                       Link,...
                       Path_Data);
         %
         if Cost_ED_ACT(Day) <= 1
             [Var_ED_I{Day},...
                 Var_ED_I_SU{Day},...
                 Var_ED_I_SD{Day},...
                 Var_ED_P{Day},...
                 Var_ED_W{Day},...
                 Var_ED_S1{Day},...
                 Var_ED_S2{Day},...
                 Var_ED_S3{Day},...
                 Var_ED_S4{Day},...
                 Cost_ED_SU(Day),...
                 Cost_ED_NL(Day),...
                 Cost_ED_P(Day),...
                 Cost_ED_S1(Day),...
                 Cost_ED_S2(Day),...
                 Cost_ED_S3(Day),...
                 Cost_ED_S4(Day),...
                 Cost_ED_ACT(Day),...
                 Cost_SYS_ACT(Day),...
                 Rate_RES{Day},...
                 Rate_RH{Day},...
                 Rate_RH_Up{Day},...
                 Rate_RH_Dn{Day},...
                 Rate_RC{Day},...
                 Rate_RES_AVR(Day),...
                 Rate_RH_AVR(Day),...
                 Rate_RH_Up_AVR(Day),...
                 Rate_RH_Dn_AVR(Day),...
                 Rate_RC_AVR(Day),...
                 PE_MAE(Day),...
                 PE_MAPE(Day),...
                 PE_MOPE(Day),...
                 PE_MUPE(Day)]...
              = ED_Auto_S1_v7(Date_Dispatch_List(Day),...
                              Var_UC_I{Day},...
                              Var_UC_P{Day},...
                              Var_UC_R_H{Day},...
                              Var_UC_R_C{Day},...
                              Cost_UC_ACT(Day),...
                              RES_Pre_Farm{Day},...
                              RES_Pre_SUM{Day},...
                              R_H_Req_Dis{Day},...
                              R_C_Req_Dis{Day},...
                              Link,...
                              Path_Data);
         end
         %
         if Cost_ED_ACT(Day) <= 1
             [Var_ED_I{Day},...
                 Var_ED_I_SU{Day},...
                 Var_ED_I_SD{Day},...
                 Var_ED_P{Day},...
                 Var_ED_W{Day},...
                 Var_ED_S1{Day},...
                 Var_ED_S2{Day},...
                 Var_ED_S3{Day},...
                 Var_ED_S4{Day},...
                 Cost_ED_SU(Day),...
                 Cost_ED_NL(Day),...
                 Cost_ED_P(Day),...
                 Cost_ED_S1(Day),...
                 Cost_ED_S2(Day),...
                 Cost_ED_S3(Day),...
                 Cost_ED_S4(Day),...
                 Cost_ED_ACT(Day),...
                 Cost_SYS_ACT(Day),...
                 Rate_RES{Day},...
                 Rate_RH{Day},...
                 Rate_RH_Up{Day},...
                 Rate_RH_Dn{Day},...
                 Rate_RC{Day},...
                 Rate_RES_AVR(Day),...
                 Rate_RH_AVR(Day),...
                 Rate_RH_Up_AVR(Day),...
                 Rate_RH_Dn_AVR(Day),...
                 Rate_RC_AVR(Day),...
                 PE_MAE(Day),...
                 PE_MAPE(Day),...
                 PE_MOPE(Day),...
                 PE_MUPE(Day)]...
              = ED_Auto_S2_v7(Date_Dispatch_List(Day),...
                              Var_UC_I{Day},...
                              Var_UC_P{Day},...
                              Var_UC_R_H{Day},...
                              Var_UC_R_C{Day},...
                              Cost_UC_ACT(Day),...
                              RES_Pre_Farm{Day},...
                              RES_Pre_SUM{Day},...
                              R_H_Req_Dis{Day},...
                              R_C_Req_Dis{Day},...
                              Link,...
                              Path_Data);
         end
         %
         if Cost_ED_ACT(Day) <= 1
             [Var_ED_I{Day},...
                 Var_ED_I_SU{Day},...
                 Var_ED_I_SD{Day},...
                 Var_ED_P{Day},...
                 Var_ED_W{Day},...
                 Var_ED_S1{Day},...
                 Var_ED_S2{Day},...
                 Var_ED_S3{Day},...
                 Var_ED_S4{Day},...
                 Cost_ED_SU(Day),...
                 Cost_ED_NL(Day),...
                 Cost_ED_P(Day),...
                 Cost_ED_S1(Day),...
                 Cost_ED_S2(Day),...
                 Cost_ED_S3(Day),...
                 Cost_ED_S4(Day),...
                 Cost_ED_ACT(Day),...
                 Cost_SYS_ACT(Day),...
                 Rate_RES{Day},...
                 Rate_RH{Day},...
                 Rate_RH_Up{Day},...
                 Rate_RH_Dn{Day},...
                 Rate_RC{Day},...
                 Rate_RES_AVR(Day),...
                 Rate_RH_AVR(Day),...
                 Rate_RH_Up_AVR(Day),...
                 Rate_RH_Dn_AVR(Day),...
                 Rate_RC_AVR(Day),...
                 PE_MAE(Day),...
                 PE_MAPE(Day),...
                 PE_MOPE(Day),...
                 PE_MUPE(Day)]...
              = ED_Auto_SS_v7(Date_Dispatch_List(Day),...
                              Var_UC_I{Day},...
                              Var_UC_P{Day},...
                              Var_UC_R_H{Day},...
                              Var_UC_R_C{Day},...
                              Cost_UC_ACT(Day),...
                              RES_Pre_Farm{Day},...
                              RES_Pre_SUM{Day},...
                              R_H_Req_Dis{Day},...
                              R_C_Req_Dis{Day},...
                              Link,...
                              Path_Data);
         end
end
save(strcat(Path_Case, Link, Case, '.mat'));