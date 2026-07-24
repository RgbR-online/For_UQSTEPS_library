within Steps.AlreadyTried;

model TestTP_PCHE_Turbine "Test d'association PCHE + Turbine sCO2"
  import Modelica.SIunits.Conversions.{from_degC, from_deg};
  import Modelica.SIunits.{Temperature, Pressure, SpecificEnthalpy, Power, Efficiency};
  import Util = Utilities.Util;
  import Steps.Utilities.CoolProp.PropsSI;  
  import Steps.Components.{PCHEGeoParam};
  import Steps.Model.{PBConfiguration, PBConfigs, SimParam, EntityConfig, EntityGeoParam, EntityThermoParam, ThermoState, HEBoundaryCondition};
  import Model.PBConfiguration;
  import ThermoPower.Choices.Init.Options;
  import ThermoPower.System;
  import ThermoPower.Gas;
  import Steps.Components.KimCorrelations;
  import Steps.Components.MaterialConductivity;    

  // 1. Configuration globale
  parameter Steps.AlreadyTried.RecupBraytonCycleConfig cfg;

  // 2. Mediums
  package medium_hot = Steps.AlreadyTried.RecupBraytonCycleConfig.medium_heater;
  package medium_cold = Steps.AlreadyTried.RecupBraytonCycleConfig.medium_main;

  // 3. Paramètres de l'échangeur
  parameter Model.HeatExchangerConfig cfg_HE     = cfg.cfg_heater;
  parameter Model.ThermoState st_source_hot      = cfg_HE.cfg_hot.st_in;
  parameter Model.ThermoState st_sink_hot        = cfg_HE.cfg_hot.st_out;
  parameter Model.ThermoState st_source_cold     = cfg_HE.cfg_cold.st_in;
  parameter Model.ThermoState st_sink_cold       = cfg_HE.cfg_cold.st_out;
  parameter Integer N_seg_HE                     = cfg_HE.cfg_hot.geo_path.N_seg;
  
  parameter Real table_k_metalwall[:,:] = [293.15, 12.1; 373.15, 16.3; 773.15, 21.5];    
  parameter Real Cf_C1 = 1.626, Cf_C2 = 1, Cf_C3 = 1;
  parameter Real use_rho_bar = -1.0;  
  parameter Real rho_bar_hot = 1.0;
  parameter Real rho_bar_cold = 1.0;    
  parameter Boolean SSInit = false "Initialisation en regime permanent";

  // =========================================================================
  // INSTANCIATION DES COMPOSANTS
  // =========================================================================

  // --- Entrée Cycle : Source de Pression ---
  ThermoPower.Gas.SourcePressure source_cold(
    redeclare package Medium = medium_cold, 
    T  = st_source_cold.T,
    p0 = st_source_cold.p,
    use_in_T = false, 
    gas(
      p(nominal = st_source_cold.p), 
      T(nominal = st_source_cold.T))) 
  annotation(
    Placement(transformation(origin = {-100, 20}, extent = {{-10, -10}, {10, 10}})));

  // --- Échangeur Haute Pression (PCHE) ---
  Steps.TPComponents.PCHE HE(
    redeclare package FluidMedium = medium_cold, 
    redeclare package FlueGasMedium = medium_hot,     
    redeclare replaceable model HeatTransfer_F = Steps.TPComponents.GnielinskiHeatTransferFV,
    redeclare replaceable model HeatTransfer_G = Steps.TPComponents.GnielinskiHeatTransferFV,
    gasFlow(
      heatTransfer(
        pitch       = cfg_HE.cfg_hot.l_pitch,
        phi         = cfg_HE.cfg_hot.a_phi,         
        Cf_C1       = Cf_C1, 
        Cf_C2       = Cf_C2, 
        Cf_C3       = Cf_C3, 
        use_rho_bar = use_rho_bar,
        rho_bar     = rho_bar_hot,
        useAverageTemperature = false)),
    fluidFlow(
      heatTransfer(
        pitch       = cfg_HE.cfg_cold.l_pitch, 
        phi         = cfg_HE.cfg_cold.a_phi,         
        Cf_C1       = Cf_C1, 
        Cf_C2       = Cf_C2, 
        Cf_C3       = Cf_C3, 
        use_rho_bar = use_rho_bar, 
        rho_bar     = rho_bar_cold,
        useAverageTemperature = false)),  
    redeclare model HeatExchangerTopology = ThermoPower.Thermal.HeatExchangerTopologies.CounterCurrentFlow, 
    cfg               = cfg_HE,
    N_G               = N_seg_HE,
    N_F               = N_seg_HE,
    SSInit            = SSInit,
    gasQuasiStatic    = true,
    fluidQuasiStatic  = true,
    metalWall(WallRes=true))
  annotation(
    Placement(transformation(origin = {-40, 20}, extent = {{-20, -20}, {20, 20}})));

  // --- Source Chaude PCHE (Circuit primaire) ---
  ThermoPower.Gas.SourcePressure source_hot(
    redeclare package Medium = medium_hot, 
    T  = st_source_hot.T,
    p0 = st_source_hot.p,
    use_in_T = false,
    gas(
      p(nominal = st_source_hot.p), 
      T(nominal = st_source_hot.T))) 
  annotation(
    Placement(transformation(origin = {-40, 80}, extent = {{-10, -10}, {10, 10}}, rotation = 270))); 

  // --- Puits Chaud PCHE (Circuit primaire) ---
  ThermoPower.Gas.SinkMassFlow sink_hot(
    redeclare package Medium = medium_hot,
    T  = st_sink_hot.T,
    p0 = st_sink_hot.p,
    use_in_T = false,
    use_in_w0 = false,
    w0 = st_source_hot.mdot)
  annotation(
    Placement(transformation(origin = {-40, -40}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));

  // --- Turbine ---
  ThermoPower.Gas.Turbine turbine(
    redeclare package Medium = medium_cold, 
    tablePhic = cfg.tablePhic_turb, 
    tableEta = cfg.tableEta_turb, 
    pstart_in = cfg.cfg_turb.st_in.p, 
    pstart_out = cfg.cfg_turb.st_out.p, 
    Tstart_in = cfg.cfg_turb.st_in.T, 
    Tstart_out = cfg.cfg_turb.st_out.T, 
    Ndesign = cfg.cfg_turb.N, 
    Tdes_in = cfg.cfg_turb.st_in.T, 
    Table = ThermoPower.Choices.TurboMachinery.TableTypes.matrix, 
    explicitIsentropicEnthalpy = true, 
    gas_in(
      p(nominal = cfg.cfg_turb.st_in.p), 
      T(nominal = cfg.cfg_turb.st_in.T), 
      h(nominal = cfg.cfg_turb.st_in.h)), 
    gas_iso(
      p(nominal = cfg.cfg_turb.st_out.p), 
      T(nominal = cfg.cfg_turb.st_out.T), 
      h(start = cfg.cfg_turb.st_out.h, nominal = cfg.cfg_turb.st_out.h))) 
  annotation(
    Placement(transformation(origin = {30, 20}, extent = {{-20, -20}, {20, 20}})));

  // --- Entraînement mécanique Turbine ---
  Modelica.Mechanics.Rotational.Sources.ConstantSpeed ConstantSpeed1(
    w_fixed = cfg.cfg_turb.N, 
    useSupport = false) 
  annotation(
    Placement(transformation(origin = {30, -30}, extent = {{-10, -10}, {10, 10}}, rotation = 90)));

  // --- Sortie Cycle : Puits de Débit ---
  ThermoPower.Gas.SinkMassFlow sink_cold(
    redeclare package Medium = medium_cold, 
    T = cfg.cfg_turb.st_out.T,
    p0 = cfg.cfg_turb.st_out.p,
    use_in_T = false,
    use_in_w0 = false,
    w0 = st_source_cold.mdot) 
  annotation(
    Placement(transformation(origin = {90, 20}, extent = {{-10, -10}, {10, 10}})));

  // --- Système Global ThermoPower ---
  inner ThermoPower.System system(allowFlowReversal = false, initOpt=ThermoPower.Choices.Init.Options.noInit) 
  annotation(
    Placement(transformation(origin = {80, 80}, extent = {{-10, -10}, {10, 10}})));

  // =========================================================================
  // INDICATEURS DE PERFORMANCE
  // =========================================================================
  Power Q_out = (HE.gasIn.h_outflow - HE.gasOut.h_outflow) * HE.gasIn.m_flow "Puissance thermique cede (W)";
  Power Q_in = (HE.waterOut.h_outflow - HE.waterIn.h_outflow) * HE.waterIn.m_flow "Puissance thermique absorbee (W)";
  Power W_turb = (turbine.gas_in.h - turbine.hout) * turbine.inlet.m_flow / 1e6 "Puissance turbine (MW)";
  Efficiency eta_turb = turbine.eta * 100 "Rendement isentropique turbine (%)";

equation
  // --- Connexions Côté Froid / Cycle sCO2 ---
  connect(source_cold.flange, HE.waterIn) annotation(
    Line(points = {{-90, 20}, {-60, 20}}, color = {0, 0, 255}, thickness = 0.5));

  connect(HE.waterOut, turbine.inlet) annotation(
    Line(points = {{-20, 20}, {10, 20}}, color = {0, 0, 255}, thickness = 0.5));

  connect(turbine.outlet, sink_cold.flange) annotation(
    Line(points = {{50, 20}, {80, 20}}, color = {0, 0, 255}, thickness = 0.5));

  // --- Connexions Côté Chaud (PCHE) ---
  connect(source_hot.flange, HE.gasIn) annotation(
    Line(points = {{-40, 70}, {-40, 40}}, color = {159, 159, 223}, thickness = 0.5)); 

  connect(HE.gasOut, sink_hot.flange) annotation(
    Line(points = {{-40, 0}, {-40, -30}}, color = {159, 159, 223}, thickness = 0.5));

  // --- Connexion Arbre Mécanique ---
  connect(ConstantSpeed1.flange, turbine.shaft_b) annotation(
    Line(points = {{30, -20}, {30, 0}}, thickness = 0.5));

  annotation(
    Diagram,
    experiment(StartTime = 0, StopTime = 60, Tolerance = 1e-3, Interval = 2),
    __OpenModelica_commandLineOptions = "--matchingAlgorithm=PFPlusExt --indexReductionMethod=dynamicStateSelection -d=initialization,NLSanalyticJacobian,aliasConflicts",    
    __OpenModelica_simulationFlags(lv = "LOG_DEBUG,LOG_NLS,LOG_NLS_V,LOG_STATS,LOG_INIT,LOG_STDOUT, -w", outputFormat = "mat", s = "dassl", nls = "homotopy"));
end TestTP_PCHE_Turbine;
