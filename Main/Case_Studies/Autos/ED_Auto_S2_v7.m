function...
[Var_ED_I,...
 Var_ED_I_SU,...
 Var_ED_I_SD,...
 Var_ED_P,...
 Var_ED_W,...
 Var_ED_S1,...
 Var_ED_S2,...
 Var_ED_S3,...
 Var_ED_S4,...
 Cost_ED_SU,...
 Cost_ED_NL,...
 Cost_ED_P,...
 Cost_ED_S1,...
 Cost_ED_S2,...
 Cost_ED_S3,...
 Cost_ED_S4,...
 Cost_ED_ACT,...
 Cost_SYS_ACT,...
 Rate_RES,...
 Rate_RH,...
 Rate_RH_Up,...
 Rate_RH_Dn,...
 Rate_RC,...
 Rate_RES_AVR,...
 Rate_RH_AVR,...
 Rate_RH_Up_AVR,...
 Rate_RH_Dn_AVR,...
 Rate_RC_AVR,...
 PE_MAE,...
 PE_MAPE,...
 PE_MOPE,...
 PE_MUPE]...
 = ED_Auto_S2_v7(Date_Dispatch,...
                 Var_UC_I,...
                 Var_UC_P,...
                 Var_UC_R_H,...
                 Var_UC_R_C,...
                 Cost_UC_ACT,...
                 RES_Pre_Farm,...
                 RES_Pre_SUM,...
                 R_H_Req_Dis,...
                 R_C_Req_Dis,...
                 Link,...
                 Path_Data)
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
%
%% ------------------------------ Decision ----------------------------- %%
Var_ED_I    = binvar(Num_Gen, Num_Hour);
Var_ED_I_SU = binvar(Num_Gen, Num_Hour);
Var_ED_I_SD = binvar(Num_Gen, Num_Hour);
Var_ED_P    = sdpvar(Num_Gen, Num_Hour);
Var_ED_W    = sdpvar(Num_Hour, Num_RES);
Var_ED_S1   = sdpvar(Num_Hour, 1);
Var_ED_S2   = sdpvar(Num_Hour, 1);
Var_ED_S3   = sdpvar(Num_Hour, Num_Branch);
Var_ED_S4   = sdpvar(Num_Hour, Num_Branch);
%
%% ----------------------------- Objective ----------------------------- %%
Cost_ED_SU  = Gen_Price(:, 5)'*sum(Var_ED_I_SU, 2);
Cost_ED_NL  = Gen_Price(:, 2)'*sum(Var_ED_I, 2);
Cost_ED_P   = Gen_Price(:, 3)'*sum(Var_ED_P, 2);
Cost_ED_S1  = LS_Price*sum(Var_ED_S1);
Cost_ED_S2  = GS_Price*sum(Var_ED_S2);
Cost_ED_S3  = BS_Price*sum(Var_ED_S3(:));
Cost_ED_S4  = BS_Price*sum(Var_ED_S4(:));
Cost_ED_ACT = Cost_ED_SU + Cost_ED_NL + Cost_ED_P...
            + Cost_ED_S1 + Cost_ED_S2 + Cost_ED_S3 + Cost_ED_S4;
%
%% ---------------------------- Constraint ----------------------------- %%
Con = [];
% Online or Offline?
Con = Con + [ Var_UC_I + Var_ED_I <= 1 ];
%
% Logical relationship
for t = 1:Num_Hour
    if t == 1
        Con = Con...
            + [   Var_ED_I_SU(:, t) - Var_ED_I_SD(:, t)...
               == Var_ED_I(:, t) ];
    end
    if t >= 2
        Con = Con...
            + [   Var_ED_I_SU(:, t) - Var_ED_I_SD(:, t)...
               == Var_ED_I(:, t) - Var_ED_I(:, t-1) ];
    end
end
%
% Segment limit
for t = 1:Num_Hour
    Con = Con + [ 0 <= Var_ED_P(:, t)...
                    <= Gen_Capacity(:, 3)...
                       .*(Var_UC_I(:, t) + Var_ED_I(:, t)) ];
end
%
% Generation limit
for t = 1:Num_Hour
    Con = Con...
        + [   Var_ED_P(:, t)...
           >= Gen_Capacity(:, 4).*(Var_UC_I(:, t) + Var_ED_I(:, t)) ];
    Con = Con...
        + [   Var_ED_P(:, t)...
           <= Gen_Capacity(:, 3).*Var_UC_I(:, t)...
            + Var_UC_R_C(:, t).*Var_ED_I(:, t) ];
end
%
% Adjustment limit based on Hot reserve
for t = 1:Num_Hour
    Con = Con...
        + [   Var_ED_P(:, t) - Var_UC_P(:, t)...
           <=  Var_UC_R_H(:, t).*Var_UC_I(:, t) + Gen_Capacity(:, 3).*Var_ED_I(:, t) ];
    Con = Con...
        + [   Var_ED_P(:, t) - Var_UC_P(:, t)...
           >= -Var_UC_R_H(:, t).*Var_UC_I(:, t) - Gen_Capacity(:, 3).*Var_ED_I(:, t) ];
end
%
% Ramping limit
for t = 2:Num_Hour
    Con = Con...
        + [   Var_ED_P(:, t) - Var_ED_P(:, t-1)...
           <= Gen_Capacity(:, 7).*     Var_UC_I(:, t-1)...
            + Gen_Capacity(:, 9).*(    Var_UC_I(:, t)...
                                     - Var_UC_I(:, t-1))...
            + Gen_Capacity(:, 3).*(1 - Var_UC_I(:, t)) ];
    Con = Con...
        + [   Var_ED_P(:, t-1) - Var_ED_P(:, t)...
           <= Gen_Capacity(:, 8).*     Var_UC_I(:, t)...
            + Gen_Capacity(:,10).*(    Var_UC_I(:, t-1)...
                                     - Var_UC_I(:, t))...
            + Gen_Capacity(:, 3).*(1 - Var_UC_I(:, t-1)) ];
end
%
% RES curtailment limit
Con = Con + [ 0 <= Var_ED_W <= RES_Farm_Dis_ACT ];
%
% Power balance
for t = 1:Num_Hour
    Con = Con...
    + [   sum(Var_ED_P(:, t))...
        + sum(Var_ED_W(t, :))...
        + Var_ED_S1(t)...
       == sum(Load_City_Dis_ACT(t, :))...
        + Var_ED_S2(t) ];
end
%
% Transmission limit
for t = 1:Num_Hour
    Con = Con...
        + [   PTDF_Gen*Var_ED_P(:, t)...
            + PTDF_RES*Var_ED_W(t, :)'...
            - PTDF_City*Load_City_Dis_ACT(t, :)'...
            - Var_ED_S3(t, :)'...
           <= Branch(:, 5) ];
       Con = Con...
           + [   PTDF_Gen*Var_ED_P(:, t)...
               + PTDF_RES*Var_ED_W(t, :)'...
               - PTDF_City*Load_City_Dis_ACT(t, :)'...
               + Var_ED_S4(t, :)'...
              >= -Branch(:, 5) ];           
end
%
% Non-negative
Con = Con + [ Var_ED_S1 == 0 ]...
          + [ Var_ED_S2 >= 0 ]...
          + [ Var_ED_S3 == 0 ]...
          + [ Var_ED_S4 == 0 ];
%
%% ------------------------------ Solve it ----------------------------- %%
disp(['Solving ED for ', datestr(Date_Dispatch)]);
ops = sdpsettings('solver', 'gurobi');
ops.gurobi.MIPGap = 0.01;
optimize(Con, Cost_ED_ACT, ops);
%
%% ------------------------------ Value it ----------------------------- %%
Var_ED_I    = round(value(Var_ED_I));
Var_ED_I_SU = round(value(Var_ED_I_SU));
Var_ED_I_SD = round(value(Var_ED_I_SD));
Var_ED_P    = value(Var_ED_P);
Var_ED_W    = value(Var_ED_W);
Var_ED_S1   = value(Var_ED_S1);
Var_ED_S2   = value(Var_ED_S2);
Var_ED_S3   = value(Var_ED_S3);
Var_ED_S4   = value(Var_ED_S4);

Cost_ED_SU = value(Cost_ED_SU);
Cost_ED_NL = value(Cost_ED_NL);
Cost_ED_P  = value(Cost_ED_P);
Cost_ED_S1 = value(Cost_ED_S1);
Cost_ED_S2 = value(Cost_ED_S2);
Cost_ED_S3 = value(Cost_ED_S3);
Cost_ED_S4 = value(Cost_ED_S4);

Cost_ED_ACT = value(Cost_ED_ACT);

Cost_SYS_ACT = Cost_ED_ACT + Cost_UC_ACT;
%
%% -------------------------------- Rate ------------------------------- %%
% RES
Rate_RES     = 100*sum(Var_ED_W, 2)./RES_SUM_Dis_ACT;
Rate_RES_AVR = round(mean(Rate_RES), 2);
%
% RH
P_Adj = Var_ED_P - Var_UC_P;

P_Adj_Up = P_Adj;
P_Adj_Up(P_Adj_Up <= 0) = 0;

P_Adj_Dn = -P_Adj;
P_Adj_Dn(P_Adj_Dn <= 0) = 0;

Rate_RH    = 100*(Var_UC_I.*abs(P_Adj))./Var_UC_R_H;
Rate_RH_Up = 100*(Var_UC_I.*P_Adj_Up)./Var_UC_R_H;
Rate_RH_Dn = 100*(Var_UC_I.*P_Adj_Dn)./Var_UC_R_H;

Rate_RH_AVR    = Rate_RH(:);
Rate_RH_Up_AVR = Rate_RH_Up(:);
Rate_RH_Dn_AVR = Rate_RH_Dn(:);

Rate_RH_AVR(isnan(Rate_RH_AVR)) = [];
Rate_RH_AVR(isinf(Rate_RH_AVR)) = [];
Rate_RH_Up_AVR(isnan(Rate_RH_Up_AVR)) = [];
Rate_RH_Up_AVR(isinf(Rate_RH_Up_AVR)) = [];
Rate_RH_Dn_AVR(isnan(Rate_RH_Dn_AVR)) = [];
Rate_RH_Dn_AVR(isinf(Rate_RH_Dn_AVR)) = [];

Rate_RH_AVR    = round(mean(Rate_RH_AVR), 2);
Rate_RH_Up_AVR = round(mean(Rate_RH_Up_AVR), 2);
Rate_RH_Dn_AVR = round(mean(Rate_RH_Dn_AVR), 2);
%
% RC
Rate_RC = 100*(Var_ED_I.*Var_ED_P)./Var_UC_R_C;
Rate_RC_AVR = Rate_RC(:);
Rate_RC_AVR(isnan(Rate_RC_AVR)) = [];
Rate_RC_AVR(isinf(Rate_RC_AVR)) = [];
Rate_RC_AVR = round(mean(Rate_RC_AVR), 2);
%
%% --------------------------------- PE -------------------------------- %%
PE_MAE  = mean(abs(RES_Pre_SUM - RES_SUM_Dis_ACT));
PE_MAPE = mean(100*abs(RES_Pre_SUM - RES_SUM_Dis_ACT)./RES_SUM_Dis_ACT);

PE_MOPE = 100*(RES_Pre_SUM - RES_SUM_Dis_ACT)./RES_SUM_Dis_ACT;
PE_MUPE = 100*(RES_SUM_Dis_ACT - RES_Pre_SUM)./RES_SUM_Dis_ACT;
PE_MOPE(PE_MOPE <= 0) = 0;
PE_MUPE(PE_MUPE <= 0) = 0;
PE_MOPE = mean(PE_MOPE);
PE_MUPE = mean(PE_MUPE);
%
yalmip('clear');
%
end