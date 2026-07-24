within Steps.AlreadyTried;

model TestTP_PCHE "Test unitaire pour l'echangeur de chaleur PCHE s'appuyant sur RecupBraytonCycleConfig_Motor"
  import Modelica.SIunits.Conversions.{from_degC, from_deg};
  import Modelica.SIunits.{Temperature, Pressure, SpecificEnthalpy};
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
  
  // 1. Instanciation du fichier de configuration global
  parameter Steps.AlreadyTried.RecupBraytonCycleConfig_Motor cfg;

  // 2. Choix de l'échangeur (garder décommenter uniquement les parties utiles)
  //package medium_hot = Steps.AlreadyTried.RecupBraytonCycleConfig_Motor.medium_HX_HP;
  package medium_hot = Steps.AlreadyTried.RecupBraytonCycleConfig_Motor.medium_main;
  package medium_cold = Steps.AlreadyTried.RecupBraytonCycleConfig_Motor.medium_main;
  //package medium_hot = Steps.AlreadyTried.RecupBraytonCycleConfig_Motor.medium_HX_LP;
  
  //parameter Model.HeatExchangerConfig cfg_HE     = cfg.cfg_HX_HP;
  parameter Model.HeatExchangerConfig cfg_HE     = cfg.cfg_recup;
  //parameter Model.HeatExchangerConfig cfg_HE     = cfg.cfg_HX_LP;
  
  // 3. Extrait des parametres thermohydrauliques et geometriques de l'echangeur
  parameter Model.ThermoState st_source_hot      = cfg_HE.cfg_hot.st_in;
  parameter Model.ThermoState st_sink_hot        = cfg_HE.cfg_hot.st_out;
  parameter Model.ThermoState st_source_cold     = cfg_HE.cfg_cold.st_in;
  parameter Model.ThermoState st_sink_cold       = cfg_HE.cfg_cold.st_out;
  parameter Integer N_seg_HE                     = cfg_HE.cfg_hot.geo_path.N_seg;
  
  // 4. Parametres de correlation et de comportement du PCHE
  parameter Real table_k_metalwall[:,:] = [293.15, 12.1; 373.15, 16.3; 773.15, 21.5];    
  parameter Real Cf_C1 = 1.626, Cf_C2 = 1, Cf_C3 = 1;
  parameter Real use_rho_bar = -1.0;  
  parameter Real rho_bar_hot = 1.0;
  parameter Real rho_bar_cold = 1.0;    
  parameter Boolean SSInit = false "Initialisation en regime permanent";

  // =========================================================================
  // INSTANCIATION DES COMPOSANTS
  // =========================================================================

  // --- Systeme Global ThermoPower ---
  inner ThermoPower.System system(allowFlowReversal = false, initOpt=ThermoPower.Choices.Init.Options.noInit) 
  annotation(
    Placement(transformation(origin = {80, 60}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));  

  // --- Source de Pression (Cote Froid) ---
  ThermoPower.Gas.SourcePressure source_cold(
    redeclare package Medium = medium_cold, 
    T  = st_source_cold.T,
    p0 = st_source_cold.p,
    use_in_T = false, 
    gas(
      p(nominal = st_source_cold.p), 
      T(nominal = st_source_cold.T))) 
  annotation(
    Placement(transformation(origin = {0, 60}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));
  
  // --- Puits de Debit Massique (Cote Froid) ---
  ThermoPower.Gas.SinkMassFlow sink_cold(
    redeclare package Medium = medium_cold, 
    T = st_sink_cold.T,
    p0 = st_sink_cold.p,
    use_in_T = false,
    use_in_w0 = false,
    w0 = st_source_cold.mdot) 
  annotation(
    Placement(transformation(origin = {0, -60}, extent = {{-10, -10}, {10, 10}}, rotation = 270)));

  // --- Source de Pression (Cote Chaud) ---
  ThermoPower.Gas.SourcePressure source_hot(
    redeclare package Medium = medium_hot, 
    T  = st_source_hot.T,
    p0 = st_source_hot.p,
    use_in_T = false,
    gas(
      p(nominal = st_source_hot.p), 
      T(nominal = st_source_hot.T))) 
  annotation(
    Placement(transformation(origin = {-80, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0))); 

  // --- Puits de Debit Massique (Cote Chaud) ---
  ThermoPower.Gas.SinkMassFlow sink_hot(
    redeclare package Medium = medium_hot,
    T  = st_sink_hot.T,
    p0 = st_sink_hot.p,
    use_in_T = false,
    use_in_w0 = false,
    w0 = st_source_hot.mdot)
  annotation(
    Placement(transformation(origin = {80, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

  // --- Echangeur de Chaleur PCHE ---
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
    Placement(transformation(origin = {0, 0}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));

  // =========================================================================
  // INDICATEURS DE PERFORMANCE
  // =========================================================================
  Modelica.SIunits.Power Q_out    = (HE.gasIn.h_outflow - HE.gasOut.h_outflow) * HE.gasIn.m_flow "Puissance thermique cedee par le cote chaud (W)";
  Modelica.SIunits.Power Q_in     = (HE.waterOut.h_outflow - HE.waterIn.h_outflow) * HE.waterIn.m_flow "Puissance thermique absorbee par le cote froid (W)";
  Boolean                isQMatch = abs(Q_out - Q_in) < 1e-3 "Indicateur d'equilibre du bilan thermique";

equation
  // Connexion de la source froide vers l'entree fluide de l'echangeur
  connect(source_cold.flange, HE.waterIn) annotation(
    Line(points = {{0, 50}, {0, 20}}, color = {0, 0, 255}, thickness = 0.5));
  
  // Connexion de la sortie fluide vers le puits froid
  connect(HE.waterOut, sink_cold.flange) annotation(
    Line(points = {{0, -20}, {0, -50}}, color = {0, 0, 255}, thickness = 0.5));
  
  // Connexion de la source chaude vers l'entree gaz de l'echangeur
  connect(source_hot.flange, HE.gasIn) annotation(
    Line(points = {{-70, 0}, {-20, 0}}, color = {159, 159, 223}, thickness = 0.5)); 
  
  // Connexion de la sortie gaz vers le puits chaud
  connect(HE.gasOut, sink_hot.flange) annotation(
    Line(points = {{20, 0}, {70, 0}}, color = {159, 159, 223}, thickness = 0.5));    

  annotation(
    Diagram,
    experiment(StartTime = 0, StopTime = 60, Tolerance = 1e-3, Interval = 2),
    __OpenModelica_commandLineOptions = "--matchingAlgorithm=PFPlusExt --indexReductionMethod=dynamicStateSelection -d=initialization,NLSanalyticJacobian,aliasConflicts",    
    __OpenModelica_simulationFlags(lv = "LOG_DEBUG,LOG_NLS,LOG_NLS_V,LOG_STATS,LOG_INIT,LOG_STDOUT, -w", outputFormat = "mat", s = "dassl", nls = "homotopy"));
end TestTP_PCHE;
