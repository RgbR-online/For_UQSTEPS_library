within Steps.Test.TPComponents;

model TestGasTurbineCO2
  extends Modelica.Icons.Example;
  
  package Medium = Steps.Media.SCO2(substanceNames = {"CO2|debug=40"});

protected
  parameter Real tablePhic[5, 4] = [1, 37, 80, 100; 1.5, 7.10E-05, 7.10E-05, 7.10E-05; 2, 8.40E-05, 8.40E-05, 8.40E-05; 2.5, 8.70E-05, 8.70E-05, 8.70E-05; 3, 1.04E-04, 1.04E-04, 1.04E-04];
  parameter Real tableEta[5, 4] = [1, 37, 80, 100; 1.5, 0.57, 0.89, 0.81; 2, 0.46, 0.82, 0.88; 2.5, 0.41, 0.76, 0.85; 3, 0.38, 0.72, 0.82];

public
  parameter Model.RCBCycleConfig cfg(
    redeclare package medium_main = Medium,
    Ns_turb  = 30000,
    mdot_main = 100,
    mdot_heater = 40
  );
  parameter Model.TurbomachineryConfig cfg_turb = cfg.cfg_turb;

  // AJOUT : Initialisation propre de la Source (p et T nominal)
  ThermoPower.Gas.SourcePressure SourceP1(
    redeclare package Medium = Medium,
    T=cfg_turb.st_in.T,
    p0=cfg_turb.st_in.p,
    gas(
      p(nominal = cfg_turb.st_in.p), 
      T(nominal = cfg_turb.st_in.T))) 
    annotation (Placement(transformation(extent={{-80,6},{-60,26}}, rotation=0)));

  Modelica.Mechanics.Rotational.Components.Inertia Inertia1(J=10000)
    annotation (Placement(transformation(extent={{10,-10},{30,10}}, rotation=0)));

  // AJOUT : Définition des états thermodynamiques nominaux et de départ pour la turbine (évite le H=0)
  ThermoPower.Gas.Turbine Turbine1(
    redeclare package Medium = Medium,
    tablePhic=tablePhic,
    tableEta=tableEta,
    pstart_in=cfg_turb.st_in.p,
    pstart_out=cfg_turb.st_out.p,
    Tstart_in=cfg_turb.st_in.T,
    Tstart_out=cfg_turb.st_out.T,
    Ndesign=cfg_turb.N,
    Tdes_in=cfg_turb.st_in.T,
    Table=ThermoPower.Choices.TurboMachinery.TableTypes.matrix,
    gas_in(
      p(nominal = cfg_turb.st_in.p), 
      T(nominal = cfg_turb.st_in.T),
      h(nominal = cfg_turb.st_in.h)),
    gas_iso(
      p(nominal = cfg_turb.st_out.p), 
      T(nominal = cfg_turb.st_out.T),
      h(start = 500000, nominal = cfg_turb.st_out.h))) 
    annotation (Placement(transformation(extent={{-40,-20},{0,20}}, rotation=0)));

  // AJOUT : Initialisation propre du Puits
  ThermoPower.Gas.SinkPressure SinkP1(
    redeclare package Medium = Medium,
    p0=cfg_turb.st_out.p,
    T=cfg_turb.st_out.T,
    gas(
      p(nominal = cfg_turb.st_out.p), 
      T(nominal = cfg_turb.st_out.T))) 
    annotation (Placement(transformation(extent={{40,6},{60,26}}, rotation=0)));

  // AJOUT : Paramètres du système pour empêcher l'inversion de débit au démarrage (très instable en sCO2)
  inner ThermoPower.System system(allowFlowReversal = false)
    annotation (Placement(transformation(extent={{80,80},{100,100}})));

equation
  connect(SourceP1.flange, Turbine1.inlet) annotation (Line(points={{-60,16},{-36,16}}, color={159,159,223}, thickness=0.5));
  connect(Turbine1.outlet, SinkP1.flange) annotation (Line(points={{-4,16},{40,16}}, color={159,159,223}, thickness=0.5));

initial equation
  Inertia1.w = cfg_turb.N;

equation
  connect(Turbine1.shaft_b, Inertia1.flange_a) annotation (Line(points={{-8,0},{-4,0},{-4,0},{10,0}}, color={0,0,0}, thickness=0.5));
      
  annotation (
    experiment(StopTime=10),
    experimentSetupOutput);
end TestGasTurbineCO2;
