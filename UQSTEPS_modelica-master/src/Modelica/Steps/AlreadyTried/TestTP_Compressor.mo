within Steps.AlreadyTried;

model TestTP_Compressor "Test unitaire pour le compresseur sCO2 s'appuyant sur RecupBraytonCycleConfig_Motor"
  import Modelica.SIunits.Conversions.{from_degC,from_deg};
  import Modelica.SIunits.{Temperature,Pressure,SpecificEnthalpy};
  import Util = Utilities.Util;
  import Steps.Utilities.CoolProp.PropsSI;
  import Steps.Components.{PCHEGeoParam};
  import Steps.Model.PBConfiguration;
  import Steps.Model.{PBConfiguration,SimParam,EntityConfig,EntityGeoParam,EntityThermoParam,ThermoState,HEBoundaryCondition};
  import ThermoPower.Choices.Init.Options;
  import ThermoPower.System;
  import ThermoPower.Gas;

  // 1. Instanciation du fichier de configuration global
  parameter Steps.AlreadyTried.RecupBraytonCycleConfig_Motor cfg;

  // 2. Utilisation du Medium de la configuration globale
  package Medium = Steps.AlreadyTried.RecupBraytonCycleConfig_Motor.medium_main;

  // =========================================================================
  // INSTANCIATION DES COMPOSANTS
  // =========================================================================

  // --- Source de Pression (Aspiration) ---
  ThermoPower.Gas.SourcePressure SourceP1(
    redeclare package Medium = Medium, 
    T = cfg.cfg_comp.st_in.T, 
    p0 = cfg.cfg_comp.st_in.p, 
    use_in_T = false, 
    use_in_p0 = false, 
    gas(
      p(start = cfg.cfg_comp.st_in.p, nominal = cfg.cfg_comp.st_in.p), 
      T(start = cfg.cfg_comp.st_in.T, nominal = cfg.cfg_comp.st_in.T))) 
  annotation(
    Placement(transformation(origin = {-80, 16}, extent = {{-10, -10}, {10, 10}})));

  // --- Source de Vitesse Constante (Entraînement mécanique) ---
  Modelica.Mechanics.Rotational.Sources.ConstantSpeed ConstantSpeed1(
    w_fixed = cfg.cfg_comp.N, 
    useSupport = false) 
  annotation(
    Placement(transformation(origin = {-46, 0}, extent = {{-10, -10}, {10, 10}})));

  // --- Compresseur ---
  ThermoPower.Gas.Compressor compresseur(
    redeclare package Medium = Medium, 
    pstart_in = cfg.cfg_comp.st_in.p, 
    pstart_out = cfg.cfg_comp.st_out.p, 
    Tstart_in = cfg.cfg_comp.st_in.T, 
    Tstart_out = cfg.cfg_comp.st_out.T, 
    tableEta = cfg.tableEta_comp, 
    tablePhic = cfg.tablePhic_comp, 
    tablePR = cfg.tablePR_comp, 
    Table = ThermoPower.Choices.TurboMachinery.TableTypes.matrix, 
    Ndesign = cfg.cfg_comp.N, 
    Tdes_in = cfg.cfg_comp.st_in.T, 
    explicitIsentropicEnthalpy = true, 
    gas_in(
      p(nominal = cfg.cfg_comp.st_in.p), 
      T(nominal = cfg.cfg_comp.st_in.T)), 
    gas_iso(
      p(nominal = cfg.cfg_comp.st_out.p), 
      T(nominal = cfg.cfg_comp.st_out.T), 
      h(start = cfg.cfg_comp.st_out.h, nominal = cfg.cfg_comp.st_out.h))) 
  annotation(
    Placement(transformation(extent = {{-20, -20}, {20, 20}})));

  // --- Puits de Débit Massique (Refoulement) ---
  ThermoPower.Gas.SinkMassFlow SinkP1(
    redeclare package Medium = Medium, 
    T = cfg.cfg_comp.st_out.T, 
    p0 = cfg.cfg_comp.st_out.p, 
    use_in_T = false, 
    use_in_w0 = false, 
    w0 = cfg.mdot_comp) 
  annotation(
    Placement(transformation(origin = {80, 16}, extent = {{-10, -10}, {10, 10}})));

  // --- Système Global ThermoPower ---
  inner ThermoPower.System system 
  annotation(
    Placement(transformation(origin = {80, 70}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

  // =========================================================================
  // INDICATEURS DE PERFORMANCE
  // =========================================================================
  Modelica.SIunits.Power W_comp = (compresseur.hout - compresseur.gas_in.h) * compresseur.inlet.m_flow / 1e6 "Puissance électrique consommée par le compresseur (MW)";
  Modelica.SIunits.Efficiency eta_comp = compresseur.eta * 100 "Rendement isentropique du compresseur (%)";

equation
  // Connexion de la source vers l'entrée du compresseur
  connect(SourceP1.flange, compresseur.inlet) annotation(
    Line(points = {{-70, 16}, {-16, 16}}, color = {159, 159, 223}, thickness = 0.5));

  // Connexion de la sortie du compresseur vers le puits
  connect(compresseur.outlet, SinkP1.flange) annotation(
    Line(points = {{16, 16}, {70, 16}}, color = {159, 159, 223}, thickness = 0.5));

  // Connexion de l'arbre mécanique
  connect(ConstantSpeed1.flange, compresseur.shaft_a) annotation(
    Line(points = {{-36, 0}, {-12, 0}}, thickness = 0.5));

  annotation(
    Diagram,
    experiment(StartTime = 0, StopTime = 1, Tolerance = 1e-2, Interval = 1),
    __OpenModelica_commandLineOptions = "--matchingAlgorithm=PFPlusExt --indexReductionMethod=dynamicStateSelection -d=initialization,NLSanalyticJacobian,aliasConflicts,bltdump",
    __OpenModelica_simulationFlags(lv = "LOG_DEBUG,LOG_NLS,LOG_NLS_V,LOG_STATS,LOG_INIT,LOG_STDOUT, -w", outputFormat = "mat", s = "dassl", nls = "homotopy"));
end TestTP_Compressor;
