within Steps.AlreadyTried;

model RecupBraytonCycle_Motor
  "Cycle de Brayton sCO2 direct à simple récupération sans recompression"

  import Modelica.SIunits.Conversions.{from_degC, from_deg};
  import Modelica.SIunits.{Power, Efficiency};

  // 1. Instanciation du package de configuration personnalisé
  parameter Steps.AlreadyTried.RecupBraytonCycleConfig_Motor cfg;

  package MediumMain   = Steps.AlreadyTried.RecupBraytonCycleConfig_Motor.medium_main;
  package MediumHeater = Steps.AlreadyTried.RecupBraytonCycleConfig_Motor.medium_HX_HP;
  package MediumCooler = Steps.AlreadyTried.RecupBraytonCycleConfig_Motor.medium_HX_LP;
  
  parameter Real table_k_metalwall[:,:] = [293.15, 12.1; 373.15, 16.3; 773.15, 21.5];    
  parameter Real Cf_C1 = 1.626, Cf_C2 = 1, Cf_C3 = 1;
  parameter Real use_rho_bar = -1.0;  
  parameter Real rho_bar_hot = 1.0;
  parameter Real rho_bar_cold = 1.0; 
  parameter Boolean SSInit = false "Initialisation en regime permanent";

  // =========================================================================
  // INSTANCIATION DES COMPOSANTS
  // =========================================================================

  // --- Système global ThermoPower (Obligatoire) ---
  inner ThermoPower.System system(
    allowFlowReversal = false, 
    initOpt = ThermoPower.Choices.Init.Options.noInit
  ) annotation(Placement(transformation(extent={{80,80},{100,100}})));

  // --- Turbomachines (Issues de ThermoPower.Gas) ---
  ThermoPower.Gas.Compressor compresseur(
    redeclare package Medium = MediumMain, 
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
      h(start = cfg.cfg_comp.st_out.h, nominal = cfg.cfg_comp.st_out.h))
  ) annotation(Placement(transformation(extent={{-70,-10},{-50,10}}, rotation=0)));

  ThermoPower.Gas.Turbine turbine(
    redeclare package Medium = MediumMain, 
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
      h(start = cfg.cfg_turb.st_out.h, nominal = cfg.cfg_turb.st_out.h))
  ) annotation(Placement(transformation(extent={{50,-10},{70,10}}, rotation=0)));

  // --- Ligne d'arbre mécanique ---
  Modelica.Mechanics.Rotational.Sources.ConstantSpeed arbre_vitesse_fixe(
    w_fixed = cfg.Ns_turb, 
    useSupport = false
  ) annotation(Placement(transformation(extent={{-10,-55},{10,-35}}, rotation=90)));

  // --- Échangeurs de Chaleur (Technologie PCHE & Marchionni/Gnielinski) ---
  
  // Unique Récupérateur (Gaz-Gaz, Haute efficacité)
  Steps.TPComponents.PCHE recuperateur(
    redeclare package FluidMedium = MediumMain, 
    redeclare package FlueGasMedium = MediumMain,     
    redeclare replaceable model HeatTransfer_F = Steps.TPComponents.GnielinskiHeatTransferFV,
    redeclare replaceable model HeatTransfer_G = Steps.TPComponents.GnielinskiHeatTransferFV,
    gasFlow(
      heatTransfer(
        pitch       = cfg.cfg_recup.cfg_hot.l_pitch,
        phi         = cfg.cfg_recup.cfg_hot.a_phi,         
        Cf_C1       = Cf_C1, 
        Cf_C2       = Cf_C2, 
        Cf_C3       = Cf_C3, 
        use_rho_bar = use_rho_bar,
        rho_bar     = rho_bar_hot,
        useAverageTemperature = false)),
    fluidFlow(
      heatTransfer(
        pitch       = cfg.cfg_recup.cfg_cold.l_pitch, 
        phi         = cfg.cfg_recup.cfg_cold.a_phi,         
        Cf_C1       = Cf_C1, 
        Cf_C2       = Cf_C2, 
        Cf_C3       = Cf_C3, 
        use_rho_bar = use_rho_bar, 
        rho_bar     = rho_bar_cold,
        useAverageTemperature = false)),  
    redeclare model HeatExchangerTopology = ThermoPower.Thermal.HeatExchangerTopologies.CounterCurrentFlow, 
    cfg               = cfg.cfg_recup,
    N_G               = cfg.cfg_recup.cfg_hot.geo_path.N_seg,
    N_F               = cfg.cfg_recup.cfg_hot.geo_path.N_seg,
    SSInit            = SSInit,
    gasQuasiStatic    = true,
    fluidQuasiStatic  = true,
    metalWall(WallRes=true))
  annotation(Placement(transformation(extent={{-10,-10},{10,10}}, rotation=0)));

  // Échangeur Haute Pression (Source Chaude / Réchauffeur)
  Steps.TPComponents.PCHE ech_haute_pression(
    redeclare package FluidMedium = MediumMain, 
    redeclare package FlueGasMedium = MediumHeater,     
    redeclare replaceable model HeatTransfer_F = Steps.TPComponents.GnielinskiHeatTransferFV,
    redeclare replaceable model HeatTransfer_G = Steps.TPComponents.GnielinskiHeatTransferFV,
    gasFlow(
      heatTransfer(
        pitch       = cfg.cfg_HX_HP.cfg_hot.l_pitch,
        phi         = cfg.cfg_HX_HP.cfg_hot.a_phi,         
        Cf_C1       = Cf_C1, 
        Cf_C2       = Cf_C2, 
        Cf_C3       = Cf_C3, 
        use_rho_bar = use_rho_bar,
        rho_bar     = rho_bar_hot,
        useAverageTemperature = false)),
    fluidFlow(
      heatTransfer(
        pitch       = cfg.cfg_HX_HP.cfg_cold.l_pitch, 
        phi         = cfg.cfg_HX_HP.cfg_cold.a_phi,         
        Cf_C1       = Cf_C1, 
        Cf_C2       = Cf_C2, 
        Cf_C3       = Cf_C3, 
        use_rho_bar = use_rho_bar, 
        rho_bar     = rho_bar_cold,
        useAverageTemperature = false)),  
    redeclare model HeatExchangerTopology = ThermoPower.Thermal.HeatExchangerTopologies.CounterCurrentFlow, 
    cfg               = cfg.cfg_HX_HP,
    N_G               = cfg.cfg_HX_HP.cfg_hot.geo_path.N_seg,
    N_F               = cfg.cfg_HX_HP.cfg_hot.geo_path.N_seg,
    SSInit            = SSInit,
    gasQuasiStatic    = true,
    fluidQuasiStatic  = true,
    metalWall(WallRes=true))
  annotation(Placement(transformation(extent={{-10,35},{10,55}}, rotation=0)));

  // Échangeur Basse Pression (Source Froide / Refroidisseur)
  Steps.TPComponents.PCHE ech_basse_pression(
    redeclare package FluidMedium = MediumMain, 
    redeclare package FlueGasMedium = MediumCooler,     
    redeclare replaceable model HeatTransfer_F = Steps.TPComponents.GnielinskiHeatTransferFV,
    redeclare replaceable model HeatTransfer_G = Steps.TPComponents.GnielinskiHeatTransferFV,
    gasFlow(
      heatTransfer(
        pitch       = cfg.cfg_HX_LP.cfg_hot.l_pitch,
        phi         = cfg.cfg_HX_LP.cfg_hot.a_phi,         
        Cf_C1       = Cf_C1, 
        Cf_C2       = Cf_C2, 
        Cf_C3       = Cf_C3, 
        use_rho_bar = use_rho_bar,
        rho_bar     = rho_bar_hot,
        useAverageTemperature = false)),
    fluidFlow(
      heatTransfer(
        pitch       = cfg.cfg_HX_LP.cfg_cold.l_pitch, 
        phi         = cfg.cfg_HX_LP.cfg_cold.a_phi,         
        Cf_C1       = Cf_C1, 
        Cf_C2       = Cf_C2, 
        Cf_C3       = Cf_C3, 
        use_rho_bar = use_rho_bar, 
        rho_bar     = rho_bar_cold,
        useAverageTemperature = false)),  
    redeclare model HeatExchangerTopology = ThermoPower.Thermal.HeatExchangerTopologies.CounterCurrentFlow, 
    cfg               = cfg.cfg_HX_LP,
    N_G               = cfg.cfg_HX_LP.cfg_hot.geo_path.N_seg,
    N_F               = cfg.cfg_HX_LP.cfg_hot.geo_path.N_seg,
    SSInit            = SSInit,
    gasQuasiStatic    = true,
    fluidQuasiStatic  = true,
    metalWall(WallRes=true))
  annotation(Placement(transformation(extent={{-10,-55},{10,-35}}, rotation=0)));
  
  // --- Sources Externes Primaires natives de ThermoPower.Gas ---
  ThermoPower.Gas.SourcePressure source_aspiration_cycle(
    redeclare package Medium = MediumMain, 
    T  = cfg.cfg_comp.st_in.T,
    p0 = cfg.cfg_comp.st_in.p,
    use_in_T = false, 
    gas(
      p(nominal = cfg.cfg_comp.st_in.p), 
      T(nominal = cfg.cfg_comp.st_in.T)));
  
  ThermoPower.Gas.SinkMassFlow puits_refoulement_cycle(
    redeclare package Medium = MediumMain, 
    T  = cfg.cfg_comp.st_in.T,
    p0 = cfg.cfg_comp.st_in.p,
    use_in_T = false,
    use_in_w0 = false,
    w0 = cfg.mdot_main);
  
  // --- Sources Externes Secondaires natives de ThermoPower.Gas ---
  ThermoPower.Gas.SourcePressure sourceHP(
    redeclare package Medium = MediumHeater, 
    T  = cfg.cfg_HX_HP.cfg_hot.st_in.T,
    p0 = cfg.cfg_HX_HP.cfg_hot.st_in.p,
    use_in_T = false, 
    gas(
      p(nominal = cfg.cfg_HX_HP.cfg_hot.st_in.p), 
      T(nominal = cfg.cfg_HX_HP.cfg_hot.st_in.T)))
  annotation(Placement(transformation(extent={{-50,42},{-30,48}}, rotation=0)));

  ThermoPower.Gas.SinkMassFlow puitsHP(
    redeclare package Medium = MediumHeater,
    T  = cfg.cfg_HX_HP.cfg_hot.st_out.T,
    p0 = cfg.cfg_HX_HP.cfg_hot.st_out.p,
    use_in_T = false,
    use_in_w0 = false,
    w0 = cfg.mdot_HX_HP)
  annotation(Placement(transformation(extent={{30,42},{50,48}}, rotation=0)));
  
  ThermoPower.Gas.SourcePressure sourceBP(
    redeclare package Medium = MediumCooler, 
    T  = cfg.cfg_HX_LP.cfg_cold.st_in.T,
    p0 = cfg.cfg_HX_LP.cfg_cold.st_in.p,
    use_in_T = false, 
    gas(
      p(nominal = cfg.cfg_HX_LP.cfg_cold.st_in.p), 
      T(nominal = cfg.cfg_HX_LP.cfg_cold.st_in.T)))
  annotation(Placement(transformation(extent={{-50,-48},{-30,-42}}, rotation=0)));

  ThermoPower.Gas.SinkMassFlow puitsBP(
    redeclare package Medium = MediumCooler,
    T  = cfg.cfg_HX_LP.cfg_cold.st_out.T,
    p0 = cfg.cfg_HX_LP.cfg_cold.st_out.p,
    use_in_T = false,
    use_in_w0 = false,
    w0 = cfg.mdot_HX_LP)
  annotation(Placement(transformation(extent={{30,-48},{50,-42}}, rotation=0)));

  // --- Variables de Performance globale ---
  Power W_turbine_net = (turbine.gas_in.h - turbine.hout) * turbine.inlet.m_flow "Puissance brute produite par la turbine";
  Power W_compressor_net = (compresseur.gas_iso.h - compresseur.gas_in.h) * compresseur.inlet.m_flow "Puissance consommée par le compresseur";
  Power W_cycle_net = W_turbine_net - W_compressor_net "Puissance nette du bloc de puissance (MW)";
  Power Q_apport_thermique = (ech_haute_pression.gasIn.h_outflow - ech_haute_pression.gasOut.h_outflow) * ech_haute_pression.gasIn.m_flow "Chaleur fournie par les sels";
  
  Efficiency eta_global "Rendement thermodynamique global du cycle (%)";

equation

  // =========================================================================
  // CONNEXIONS DU CIRCUIT PRINCIPAL sCO2 (Boucle Fermée Directe)
  // =========================================================================
  
  connect(source_aspiration_cycle.flange, compresseur.inlet);
  
  // État 1 -> État 2 : Compresseur
  connect(compresseur.outlet, recuperateur.waterIn) annotation(Line(points={{-50,8},{-30,8},{-30,5},{-10,5}}, color={0,0,255})); 

  // État 2 -> État 3 : Passage du fluide comprimé froid dans le Récupérateur
  connect(recuperateur.waterOut, ech_haute_pression.gasOut) annotation(Line(points={{10,5},{25,5},{25,25},{5,25},{5,35}}, color={0,0,255})); 

  // État 3 -> État 4/5 : Apport de chaleur externe (Échangeur HP) vers la Turbine
  connect(ech_haute_pression.gasIn, turbine.inlet) annotation(Line(points={{-5,35},{-5,20},{35,20},{35,8},{50,8}}, color={255,0,0})); 

  // État 5 -> État 6 : Détente dans la Turbine
  connect(turbine.outlet, recuperateur.gasIn) annotation(Line(points={{50,-8},{30,-8},{30,-5},{10,-5}}, color={255,0,0})); 

  // État 6 -> État 7 : Restitution des calories au fluide froid dans le Récupérateur
  connect(recuperateur.gasOut, ech_basse_pression.gasIn) annotation(Line(points={{-10,-5},{-25,-5},{-25,-25},{-5,-25},{-5,-35}}, color={255,127,0})); 

  
  connect(ech_basse_pression.gasOut, puits_refoulement_cycle.flange);

  // =========================================================================
  // CONNEXIONS MÉCANIQUES (Arbre Unique Commun)
  // =========================================================================
  connect(turbine.shaft_b, compresseur.shaft_a) annotation(Line(points={{50,0},{-50,0}}, color={0,0,0}));
  connect(compresseur.shaft_b, arbre_vitesse_fixe.flange) annotation(Line(points={{-70,0},{-80,0},{-80,-45},{-10,-45}}, color={0,0,0}));

  // =========================================================================
  // CONNEXIONS DES CIRCUITS ANNEXES (Sources et Puits d'Énergie)
  // =========================================================================
  
  // Circuit de la Source Chaude (Sels fondus)
  connect(sourceHP.flange, ech_haute_pression.waterIn) annotation(Line(points={{-30,45},{-10,45}}, color={139,0,0}));
  connect(ech_haute_pression.waterOut, puitsHP.flange) annotation(Line(points={{10,45},{30,45}}, color={139,0,0}));

  // Circuit de la Source Froide (Eau de refroidissement)
  connect(sourceBP.flange, ech_basse_pression.waterIn) annotation(Line(points={{-30,-45},{-10,-45}}, color={0,128,128}));
  connect(ech_basse_pression.waterOut, puitsBP.flange) annotation(Line(points={{10,-45},{30,-45}}, color={0,128,128}));

  // =========================================================================
  // CALCULS DES RENDEMENTS
  // =========================================================================
  eta_global = if Q_apport_thermique > 1e-3 then (W_cycle_net / Q_apport_thermique) * 100 else 0;

  annotation(
    experiment(StartTime = 0, StopTime = 1, Tolerance = 1e-3, Interval = 0.01),
    __OpenModelica_commandLineOptions = "--matchingAlgorithm=PFPlusExt --indexReductionMethod=dynamicStateSelection -d=initialization,NLSanalyticJacobian"
  );
end RecupBraytonCycle_Motor;
