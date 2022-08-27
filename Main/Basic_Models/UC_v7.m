clc;
clear;
close all;
%% ------------------------------ Setting ------------------------------ %%
Date_Dispatch = '2020-03-06';
Mode_RES      = 'OPO';
OVar_H_w      = 1;
%
%% ------------------------------- Path -------------------------------- %%
Ini_Path = which('Location_CPO_v7.m');
Ini_Size = size('Location_CPO_v7.m', 2);
Link = Ini_Path(end - Ini_Size);
Path_Data = strcat(Ini_Path(1:end - Ini_Size - 1), Link, 'Database');
Path_Temp = strcat(Ini_Path(1:end - Ini_Size - 1), Link, 'Temp');
%
%% ------------------------------ Loading ------------------------------ %%
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
if Mode_RES == 'OPO'
    RES = OVar_H_w*RES_Farm_Dis_DAF;
end
if Mode_RES == 'PPO'
    RES = RES_Farm_Dis_ACT;
end
%
%% ------------------------------ Decision ----------------------------- %%
Var_UC_I    = binvar(Num_Gen, Num_Hour);
Var_UC_I_SU = binvar(Num_Gen, Num_Hour);
Var_UC_I_SD = binvar(Num_Gen, Num_Hour);
Var_UC_I_RC = binvar(Num_Gen, Num_Hour);
Var_UC_P    = sdpvar(Num_Gen, Num_Hour);
Var_UC_W    = sdpvar(Num_Hour,Num_RES);
Var_UC_R_H  = sdpvar(Num_Gen, Num_Hour);
Var_UC_R_C  = sdpvar(Num_Gen, Num_Hour);
%
%% ----------------------------- Objective ----------------------------- %%
Cost_UC_SU = Gen_Price(:, 5)'*sum(Var_UC_I_SU, 2);
Cost_UC_NL = Gen_Price(:, 2)'*sum(Var_UC_I, 2);
Cost_UC_P  = Gen_Price(:, 3)'*sum(Var_UC_P, 2);
Cost_UC_RH = Gen_Price(:, 7)'*sum(Var_UC_R_H, 2);
Cost_UC_RC = Gen_Price(:, 8)'*sum(Var_UC_R_C, 2);
Cost_SYS_EXP = Cost_UC_SU...
             + Cost_UC_NL...
             + Cost_UC_P...
             + Cost_UC_RH...
             + Cost_UC_RC;
%
%% ---------------------------- Constraint ----------------------------- %%
Con = [];
% Generation limit
for t = 1:Num_Hour
    Con = Con...
        + [   Var_UC_P(:, t)     - Var_UC_R_H(:, t)...
           >= Gen_Capacity(:, 4).* Var_UC_I(:, t) ];
    Con = Con...
        + [   Var_UC_P(:, t)     + Var_UC_R_H(:, t)...
           <= Gen_Capacity(:, 3).* Var_UC_I(:, t) ];
end
%
% Segment limit
for t = 1:Num_Hour
    Con = Con...
        + [ 0 <= Var_UC_P(:, t)...
              <= Gen_Capacity(:, 3).*Var_UC_I(:, t) ];
end
%
% Hot reserve limit
for t = 1:Num_Hour
    Con = Con...
        + [ 0 <= Var_UC_R_H(:, t)...
              <= Gen_Capacity(:, 11).*Var_UC_I(:, t) ];
end
%
% Cool reserve limit
for t = 1:Num_Hour
    Con = Con...
        + [   Var_UC_R_C(:, t)...
           >= Gen_Capacity(:, 4).*Var_UC_I_RC(:, t) ];
    Con = Con...
        + [   Var_UC_R_C(:, t)...
           <= Gen_Capacity(:,12).*Var_UC_I_RC(:, t) ];
end
%
% Cool reserve flag
Con = Con...
    + [ Var_UC_I_RC + Var_UC_I <= 1 ];
%
% Logical relationship
for t = 1:Num_Hour
    if t == 1
        Con = Con...
            + [   Var_UC_I_SU(:, t) - Var_UC_I_SD(:, t)...
               == Var_UC_I(:, t) ];
    end
    if t >= 2
        Con = Con...
            + [   Var_UC_I_SU(:, t) - Var_UC_I_SD(:, t)...
               == Var_UC_I(:, t) - Var_UC_I(:, t-1) ];
    end
end
%
% Min ON/OFF
for i = 1:Num_Gen
    % ON
    for t = Gen_Capacity(i, 5):Num_Hour
        Con = Con + [   sum(Var_UC_I_SU(i, t-Gen_Capacity(i, 5)+1:t))...
                     <= Var_UC_I(i, t) ];
    end
    % OFF
    for t = Gen_Capacity(i, 6):Num_Hour
        Con = Con + [   sum(Var_UC_I_SD(i, t-Gen_Capacity(i, 6)+1:t))...
                     <= 1 - Var_UC_I(i, t) ];
    end
end
%
% Ramping limit
for t = 2:Num_Hour
    Con = Con...
        + [   Var_UC_P(:, t) - Var_UC_P(:, t-1)...
           <= Gen_Capacity(:, 7).*     Var_UC_I(:, t-1)...
            + Gen_Capacity(:, 9).*(    Var_UC_I(:, t)...
                                     - Var_UC_I(:, t-1))...
            + Gen_Capacity(:, 3).*(1 - Var_UC_I(:, t)) ];
    Con = Con...
        + [   Var_UC_P(:, t-1) - Var_UC_P(:, t)...
           <= Gen_Capacity(:, 8).*     Var_UC_I(:, t)...
            + Gen_Capacity(:,10).*(    Var_UC_I(:, t-1)...
                                     - Var_UC_I(:, t))...
            + Gen_Capacity(:, 3).*(1 - Var_UC_I(:, t-1)) ];
end
%
% RES curtailment limit
Con = Con...
    + [ 0 <= Var_UC_W <= RES ];
%
% Thermal untis
for i = Unit_Thermal
    Con = Con...
        + [ Var_UC_I_RC(i, :) == 0];
end
%
% Power balance
for t = 1:Num_Hour
    Con = Con...
        + [   sum(Var_UC_P(:, t))...
            + sum(Var_UC_W(t, :))...
           == sum(Load_City_Dis_DAF(t, :)) ];
end
%
% Transmission limit
for t = 1:Num_Hour
    Con = Con...
        + [ - Branch(:, 5)...
           <= PTDF_Gen*Var_UC_P(:, t)...
            + PTDF_RES*Var_UC_W(t, :)'...
            - PTDF_City*Load_City_Dis_DAF(t, :)'...
           <= Branch(:, 5) ];
end
%
% Reserve requirement (>= or ==)
Con = Con + [   sum(Var_UC_R_H)' >= R_H_Req_Dis ];
Con = Con + [   sum(Var_UC_R_H)' + sum(Var_UC_R_C)'...
             >= R_H_Req_Dis + R_C_Req_Dis];
%
%% ------------------------------ Solve it ----------------------------- %%
disp(['Solving UC for ', datestr(Date_Dispatch)]);
ops = sdpsettings('solver', 'gurobi');
ops.gurobi.MIPGap = 0.01;
sol = optimize(Con, Cost_SYS_EXP, ops);
%
%% ------------------------ Value and Round it ------------------------- %%
% Round them for avoiding numerical problems
Var_UC_I    = round(value(Var_UC_I));
Var_UC_I_SU = round(value(Var_UC_I_SU));
Var_UC_I_SD = round(value(Var_UC_I_SD));
Var_UC_I_RC = round(value(Var_UC_I_RC));
Var_UC_P    = round(value(Var_UC_P), 4);
Var_UC_W    = round(value(Var_UC_W), 4);
Var_UC_R_H  = round(value(Var_UC_R_H), 4);
Var_UC_R_C  = round(value(Var_UC_R_C), 4);
%
% Avoid numerical problems
% Var_UC_P(Var_UC_P <= 1) = 0;
% Var_UC_R_H(Var_UC_R_H <= 1) = 1;
%
% Cost
Cost_UC_SU   = value(Cost_UC_SU);
Cost_UC_NL   = value(Cost_UC_NL);
Cost_UC_P    = value(Cost_UC_P);
Cost_UC_RH   = value(Cost_UC_RH);
Cost_UC_RC   = value(Cost_UC_RC);
Cost_UC_ACT  = Cost_UC_SU + Cost_UC_NL + Cost_UC_RH + Cost_UC_RC;
Cost_SYS_EXP = value(Cost_SYS_EXP);
% yalmip('clear');
%
%% --------------------------- Check network --------------------------- %%
Trans_power = zeros(Num_Branch, Num_Hour);
Trans_rate  = zeros(Num_Branch, Num_Hour);
for t = 1:Num_Hour
    Trans_power(:, t) = PTDF_Gen*Var_UC_P(:, t)...
                      + PTDF_RES*Var_UC_W(t, :)'...
                      - PTDF_City*Load_City_Dis_ACT(t, :)' ;
end
for i = 1:Num_Branch
    for t = 1:Num_Hour
        Trans_rate(i, t) = round(Trans_power(i, t)/(Branch(i, 5)), 2);
    end   
end
Trans_rate_max_avr = zeros(Num_Branch, 2);
for i = 1:Num_Branch
    Trans_rate_max_avr(i, 1) = max(abs(Trans_rate(i, :))); 
    Trans_rate_max_avr(i, 2) = sum(abs(Trans_rate(i, :)))/Num_Hour; 
end
%
%% ---------------------------- Pkg for ED ----------------------------- %%
Pkg{1}  = Date_Dispatch;
Pkg{2}  = Var_UC_I;
Pkg{3}  = Var_UC_P;
Pkg{4}  = Var_UC_R_H;
Pkg{5}  = Var_UC_R_C;
Pkg{6}  = Cost_UC_ACT;
Pkg{7}  = Cost_SYS_EXP;
Pkg{8}  = Cost_UC_SU;
Pkg{9}  = Cost_UC_NL;
Pkg{10} = Cost_UC_RH;
Pkg{11} = Cost_UC_RC;

% save(strcat(Path_Temp, Link, 'Pkg.mat'), 'Pkg');
% ED_v7;