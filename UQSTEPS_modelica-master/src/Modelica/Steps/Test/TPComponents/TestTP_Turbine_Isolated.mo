within Steps.Test.TPComponents;

model TestTP_Turbine_Isolated
  "Test isole de la Turbine1, sans dependance a RCBCycleConfig/TurbomachineryConfig,
   pour determiner si le crash CoolProp vient du composant Turbine lui-meme
   ou de l'interaction avec le reste du cycle."

  import Modelica.SIunits.Conversions.{from_degC, from_deg};
  import Modelica.SIunits.{Temperature, Pressure, SpecificEnthalpy, MassFlowRate};
  import ThermoPower.Choices.Init.Options;
  import ThermoPower.System;
  import ThermoPower.Gas;

  package Medium = Steps.Media.SCO2(
    substanceNames = {"CO2|debug=40"}
  );

  // ---- Point de fonctionnement fige (repris tel quel de RCBCycleConfig) ----
  // st_in  == st_heater_cold_out : p = p_comp_out = 20e6 Pa, T = from_degC(710)
  // st_out == st_HTR_hot_in      : p = p_comp_in  = 9e6  Pa, T = from_degC(636.95057734)
  parameter Modelica.SIunits.Pressure p_in     = 20e6;
  parameter Modelica.SIunits.Temperature T_in  = from_degC(710);
  // w_in n'est plus impose (cf. SourcePressure ci-dessous) : gardee ici
  // uniquement comme valeur de reference pour comparer le debit resultant
  // du calcul de la turbine (Turbine1.inlet.m_flow) au débit nominal attendu.
  parameter Modelica.SIunits.MassFlowRate w_in_ref = 40 "mdot_heater, valeur de reference/comparaison uniquement";

  parameter Modelica.SIunits.Pressure p_out    = 9e6;
  parameter Modelica.SIunits.Temperature T_out = from_degC(636.95057734);

  // vitesse de rotation - identique a l'original (Ns_turb impose dans TestTP_Turbine)
  parameter Real N_turb = 30000;

  // enthalpies de reference, calculees directement (evite de dependre de ThermoState/ Model.*)
  parameter Modelica.SIunits.SpecificEnthalpy h_in  =
    Medium.specificEnthalpy_pT(p = p_in,  T = T_in);
  parameter Modelica.SIunits.SpecificEnthalpy h_out =
    Medium.specificEnthalpy_pT(p = p_out, T = T_out);

protected
  parameter Real tablePhic[5, 4] = [1, 37, 80, 100; 1.5, 7.10E-05, 7.10E-05, 7.10E-05; 2, 8.40E-05, 8.40E-05, 8.40E-05; 2.5, 8.70E-05, 8.70E-05, 8.70E-05; 3, 1.04E-04, 1.04E-04, 1.04E-04];
  parameter Real tableEta[5, 4]  = [1, 37, 80, 100; 1.5, 0.57, 0.89, 0.81; 2, 0.46, 0.82, 0.88; 2.5, 0.41, 0.76, 0.85; 3, 0.38, 0.72, 0.82];

public
  // SourcePressure impose p_in/T_in comme deux VRAIES conditions aux limites.
  // Le debit n'est plus impose : il resulte du calcul interne de la turbine
  // (relation Phic(rapport de pression, vitesse reduite) -> debit).
  // Cela leve le sur-contraint qui existait avec SourceMassFlow + SinkPressure
  // (debit ET les deux pressions imposes en meme temps que la caracteristique
  // de la turbine, ce qui rendait le systeme algebriquement fragile).
  ThermoPower.Gas.SourcePressure SourceP1(
    redeclare package Medium = Medium,
    T        = T_in,
    p0       = p_in,
    use_in_T = false,
    gas(
      p(nominal = p_in),
      T(nominal = T_in)))
  annotation(
    Placement(transformation(origin = {-60, 16}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

  ThermoPower.Gas.Turbine Turbine1(
    redeclare package Medium = Medium,
    fileName    = Modelica.Utilities.Files.loadResource("modelica://Steps/Resources/Data/turbine_map.txt"),
    tablePhic   = tablePhic,
    tableEta    = tableEta,
    pstart_in   = p_in,
    pstart_out  = p_out,
    Tstart_in   = T_in,
    Tstart_out  = T_out,
    Ndesign     = N_turb,
    Tdes_in     = T_in,
    Table       = ThermoPower.Choices.TurboMachinery.TableTypes.file,
    gas_in(
      p(nominal = p_in),
      T(nominal = T_in),
      h(start = h_in, nominal = h_in)),
    gas_iso(
      p(nominal = p_out),
      T(nominal = T_out),
      h(start = h_out, nominal = h_out)))
  annotation(
    Placement(transformation(extent = {{-40, -4}, {0, 36}}, rotation = 0)));

  ThermoPower.Gas.SinkPressure SinkP1(
    redeclare package Medium = Medium,
    p0 = p_out,
    T  = T_out,
    gas(
      p(nominal = p_out),
      T(nominal = T_out)))
  annotation(
    Placement(transformation(origin = {40, 16}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));

  Modelica.Mechanics.Rotational.Sources.ConstantSpeed const_speed_turb(
    w_fixed = N_turb, useSupport = false)
  annotation(
    Placement(transformation(origin = {60, -20}, extent = {{-5, -5}, {5, 5}}, rotation = 0)));

  inner ThermoPower.System system(
    allowFlowReversal = false,
    initOpt = ThermoPower.Choices.Init.Options.noInit)
  annotation(
    Placement(transformation(extent = {{60, 60}, {80, 80}})));

  Modelica.SIunits.Power W_turb =
    (Turbine1.gas_in.h - Turbine1.hout) * Turbine1.inlet.m_flow / 1e6
    "MW, puissance nette de la turbine";
  Modelica.SIunits.Efficiency eta_turb = Turbine1.eta * 100;
  Modelica.SIunits.MassFlowRate w_result = Turbine1.inlet.m_flow
    "Debit resultant du calcul de la turbine, a comparer a w_in_ref";

equation
  connect(SourceP1.flange, Turbine1.inlet)
  annotation(
    Line(points = {{-50, 16}, {-36, 16}}, color = {159, 159, 223}, thickness = 0.5));

  connect(Turbine1.outlet, SinkP1.flange)
  annotation(
    Line(points = {{-4, 16}, {30, 16}}, color = {159, 159, 223}));

  connect(Turbine1.shaft_b, const_speed_turb.flange)
  annotation(
    Line(points = {{-10, -4}, {-10, -20}, {55, -20}}));

  annotation(
    Diagram(graphics),
    experiment(StartTime = 0, StopTime = 1, Tolerance = 1e-3, Interval = 1),
    __OpenModelica_commandLineOptions = "--matchingAlgorithm=PFPlusExt --indexReductionMethod=dynamicStateSelection -d=initialization,NLSanalyticJacobian,aliasConflicts,bltdump",
    __OpenModelica_simulationFlags(lv = "LOG_DEBUG,LOG_NLS,LOG_NLS_V,LOG_STATS,LOG_INIT,LOG_STDOUT, -w", outputFormat = "mat", s = "dassl", nls = "homotopy"));

end TestTP_Turbine_Isolated;
