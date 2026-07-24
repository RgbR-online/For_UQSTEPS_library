within Steps.AlreadyTried;

record RecupBraytonCycleConfig_Motor
  "Configuration pour un cycle de Brayton sCO2 direct à simple récupération (Mode Moteur)"
  
  import Modelica.SIunits.Conversions.{from_degC, from_deg};
  import Modelica.SIunits.{Temperature, Pressure, SpecificEnthalpy, MassFlowRate};
  import Util = Utilities.Util;

  // ---- Choix des Fluides (Media) ----
  replaceable package medium_main   = Steps.Media.SCO2 constrainedby Modelica.Media.Interfaces.PartialPureSubstance;
  replaceable package medium_HX_LP = Steps.Media.SCO2 constrainedby Modelica.Media.Interfaces.PartialPureSubstance;
  replaceable package medium_HX_HP= Steps.Media.SCO2 constrainedby Modelica.Media.Interfaces.PartialPureSubstance;
//  package medium_HX_LP = ThermoPower.Water.StandardWater constrainedby Modelica.Media.Interfaces.PartialPureSubstance;
//  package medium_HX_HP= Steps.Media.MoltenSalt.MoltenSalt_pT constrainedby Modelica.Media.Interfaces.PartialPureSubstance;
  
  // ---- Performances des Turbomachines ----
  parameter Real eta_comp   = 0.89 "Efficacité du compresseur principal";
  parameter Real eta_turb   = 0.89 "Efficacité de la turbine";
  parameter Real Ns_comp    = 314 "Vitesse nominale compresseur";
  parameter Real Ns_turb    = 314 "Vitesse nominale turbine";
  
  // ---- Pressions et Températures issues des points de fonctionnement ----
  // Niveaux de pression du cycle
  parameter Modelica.SIunits.Pressure p_high = 366e5 "Haute pression (366 bar)";
  parameter Modelica.SIunits.Pressure p_low  = 78e5  "Basse pression (78 bar)";
  parameter Modelica.SIunits.Pressure p_HX_HP= 366e5 "Haute pression (366 bar)";
  parameter Modelica.SIunits.Pressure p_HX_LP  = 78e5  "Basse pression (78 bar)";
  
  // Températures imposées (converties depuis les °C du Beamer LaTeX)
  parameter Modelica.SIunits.Temperature T1 = from_degC(205) "Entrée Compresseur";
  parameter Modelica.SIunits.Temperature T2 = from_degC(294) "Sortie Compresseur / Entrée Récupérateur (froid)";
  parameter Modelica.SIunits.Temperature T3 = from_degC(438) "Sortie Récupérateur (froid) / Entrée Échangeur HP";
  parameter Modelica.SIunits.Temperature T4 = from_degC(595) "Sortie Échangeur HP / Entrée Turbine (T4 = T5)";
  parameter Modelica.SIunits.Temperature T6 = from_degC(499) "Sortie Turbine / Entrée Récupérateur (chaud)";
  parameter Modelica.SIunits.Temperature T7 = from_degC(337) "Sortie Récupérateur (chaud) / Entrée Échangeur BP";
  parameter Modelica.SIunits.Temperature T8 = from_degC(205) "Sortie Échangeur BP (T8 = T1)";

  // Températures indicatives pour les boucles de sources secondaires
  parameter Modelica.SIunits.Temperature T_source_HX_HP_in  = from_degC(600);
  parameter Modelica.SIunits.Temperature T_source_HX_HP_out = from_degC(400);
  parameter Modelica.SIunits.Temperature T_source_HX_LP_in  = from_degC(200);
  parameter Modelica.SIunits.Temperature T_source_HX_LP_out = from_degC(330);

  // ---- Débits massiques (Valeurs par défaut modifiables) ----
  parameter Modelica.SIunits.MassFlowRate mdot_main   = 55 "Débit sCO2 principal";
  parameter Modelica.SIunits.MassFlowRate mdot_comp   = 55 "Débit sCO2 principal pour le bon fonctionnement du compresseur";
  parameter Modelica.SIunits.MassFlowRate mdot_turb   = 240 "Débit sCO2 principal pour le bon focntionnement de la turbine";
  parameter Modelica.SIunits.MassFlowRate mdot_HX_HP= 40  "Débit de la source chaude";
  parameter Modelica.SIunits.MassFlowRate mdot_HX_LP = 40  "Débit de la source froide";

  parameter Integer N_seg = 10 "Nombre de segments par défaut pour la discrétisation des échangeurs";

  // ---- Propriétés thermophysiques des parois (Ex: Inconel / Alliage X-750) ----
  parameter Modelica.SIunits.Density rho_wall             = 8280 "kg/m3";
  parameter Modelica.SIunits.SpecificHeatCapacity cp_wall = 431  "J/kg-K";

  // =========================================================================
  // DÉFINITION DES ÉTATS THERMODYNAMIQUES (Points 1 à 8)
  // =========================================================================
  
  parameter Model.ThermoState st1(p = p_low,  T = T1, mdot = mdot_main, h = medium_main.specificEnthalpy_pT(p = st1.p, T = st1.T));
  parameter Model.ThermoState st2(p = p_high, T = T2, mdot = mdot_main, h = medium_main.specificEnthalpy_pT(p = st2.p, T = st2.T));
  parameter Model.ThermoState st3(p = p_high, T = T3, mdot = mdot_main, h = medium_main.specificEnthalpy_pT(p = st3.p, T = st3.T));
  parameter Model.ThermoState st4(p = p_high, T = T4, mdot = mdot_main, h = medium_main.specificEnthalpy_pT(p = p_high, T = T4)); // État 4/5
  parameter Model.ThermoState st6(p = p_low,  T = T6, mdot = mdot_main, h = medium_main.specificEnthalpy_pT(p = st6.p, T = st6.T));
  parameter Model.ThermoState st7(p = p_low,  T = T7, mdot = mdot_main, h = medium_main.specificEnthalpy_pT(p = st7.p, T = st7.T));

  // États pour les circuits secondaires (Sources)
  parameter Model.ThermoState st_src_HX_HP_in(p = p_HX_HP, T = T_source_HX_HP_in, mdot = mdot_HX_HP, h = medium_main.specificEnthalpy_pT(p = st_src_HX_HP_in.p, T = st_src_HX_HP_in.T));
  parameter Model.ThermoState st_src_HX_HP_out(p = p_HX_HP, T = T_source_HX_HP_out, mdot = mdot_HX_HP, h = medium_main.specificEnthalpy_pT(p = st_src_HX_HP_out.p, T = st_src_HX_HP_out.T));
  parameter Model.ThermoState st_src_HX_LP_in(p = p_HX_LP, T = T_source_HX_LP_in, mdot = mdot_HX_LP, h = medium_main.specificEnthalpy_pT(p = st_src_HX_LP_in.p, T = st_src_HX_LP_in.T));
  parameter Model.ThermoState st_src_HX_LP_out(p = p_HX_LP, T = T_source_HX_LP_out, mdot = mdot_HX_LP, h = medium_main.specificEnthalpy_pT(p = st_src_HX_LP_out.p, T = st_src_HX_LP_out.T));
  
  parameter Model.ThermoState st_recup_wall(p = p_high, T = (st6.T + st2.T) / 2, h = medium_main.specificEnthalpy_pT(p = st_recup_wall.p, T = st_recup_wall.T), mdot = mdot_main);
  parameter Model.ThermoState st_HX_LP_wall(p = p_low, T = (st7.T + st_src_HX_LP_in.T) / 2, h = medium_main.specificEnthalpy_pT(p = st_HX_LP_wall.p, T = st_HX_LP_wall.T), mdot = mdot_main);
  parameter Model.ThermoState st_HX_HP_wall(p = p_high, T = (st_src_HX_HP_in.T + st3.T) / 2, h = medium_main.specificEnthalpy_pT(p = st_HX_HP_wall.p, T = st_HX_HP_wall.T), mdot = mdot_main);

  // =========================================================================
  // CONFIGURATION GÉOMÉTRIQUE ET THERMIQUE DES COMPOSANTS
  // =========================================================================

  // ---- 1. ÉCHANGEUR BASSE PRESSION ----
  parameter Modelica.SIunits.Radius r_channel_HX_LP = 1.5e-3;
  parameter Modelica.SIunits.Radius w_sd_HX_LP       = 2.3e-3;
  parameter Modelica.SIunits.Radius h_sd_HX_LP       = 4.17e-3;
  parameter Modelica.SIunits.Length t_ch_HX_LP       = 0.51e-3;
  
  parameter Modelica.SIunits.Length l_pitch_HX_LP = 12.3e-3 "pitch length";
  parameter Modelica.SIunits.Length a_phi_HX_LP   = 35      "pitch angle";

  parameter Modelica.SIunits.Length L_HX_LP          = 2.5;
  parameter Integer N_ch_HX_LP                       = 30000;

  parameter Model.AreaGeometry ga_HX_LP_hot  = Model.SetAreaGeometry_SemiCircle(r = r_channel_HX_LP);
  parameter Model.AreaGeometry ga_HX_LP_cold = Model.SetAreaGeometry_SemiCircle(r = r_channel_HX_LP);
  parameter Model.AreaGeometry ga_HX_LP_wall = Model.SetAreaGeometry_Wall(r = r_channel_HX_LP, w = w_sd_HX_LP, h = h_sd_HX_LP, p1 = t_ch_HX_LP);
  parameter Model.PathGeometry gp_HX_LP_hot  = Model.SetPathGeometry(geo_area = ga_HX_LP_hot, L = L_HX_LP, N_seg = N_seg);
  parameter Model.PathGeometry gp_HX_LP_cold = Model.SetPathGeometry(geo_area = ga_HX_LP_cold, L = L_HX_LP, N_seg = N_seg);
  parameter Model.PathGeometry gp_HX_LP_wall = Model.SetPathGeometry(geo_area = ga_HX_LP_wall, L = L_HX_LP, N_seg = N_seg);
  
  parameter Model.HeatExchangerConfig cfg_HX_LP(
    cfg_hot(
      st_in    = st7, 
      st_out   = st1, 
      geo_area = ga_HX_LP_hot, 
      geo_path = gp_HX_LP_hot, 
      N_ch     = N_ch_HX_LP, 
      u        = 0,
      l_pitch  = l_pitch_HX_LP,
      a_phi    = a_phi_HX_LP
    ),
    cfg_cold(
      st_in    = st_src_HX_LP_in, 
      st_out   = st_src_HX_LP_out, 
      geo_area = ga_HX_LP_cold, 
      geo_path = gp_HX_LP_cold, 
      N_ch     = N_ch_HX_LP, 
      u        = 0,
      l_pitch  = l_pitch_HX_LP,
      a_phi    = a_phi_HX_LP
    ),
    cfg_fluid = cfg_HX_LP.cfg_cold,
    cfg_gas   = cfg_HX_LP.cfg_hot,
    cfg_wall(st_init = st_HX_LP_wall, geo_area = ga_HX_LP_wall, geo_wall = gp_HX_LP_wall, rho_mcm = rho_wall * cp_wall, lambda = 200)
  );

  // ---- 2. RÉCUPÉRATEUR ----
  parameter Modelica.SIunits.Radius r_channel_recup = 1.5e-3;
  parameter Modelica.SIunits.Radius w_sd_recup       = 2.3e-3;
  parameter Modelica.SIunits.Radius h_sd_recup       = 4.17e-3;
  parameter Modelica.SIunits.Length t_ch_recup       = 0.51e-3;
  
  parameter Modelica.SIunits.Length l_pitch_recup = 12.3e-3 "pitch length";
  parameter Modelica.SIunits.Length a_phi_recup   = 35      "pitch angle";

  parameter Modelica.SIunits.Length L_recup          = 2.5;
  parameter Integer N_ch_recup                       = 30000;

  parameter Model.AreaGeometry ga_recup_hot  = Model.SetAreaGeometry_SemiCircle(r = r_channel_recup);
  parameter Model.AreaGeometry ga_recup_cold = Model.SetAreaGeometry_SemiCircle(r = r_channel_recup);
  parameter Model.AreaGeometry ga_recup_wall = Model.SetAreaGeometry_Wall(r = r_channel_recup, w = w_sd_recup, h = h_sd_recup, p1 = t_ch_recup);
  parameter Model.PathGeometry gp_recup_hot  = Model.SetPathGeometry(geo_area = ga_recup_hot, L = L_recup, N_seg = N_seg);
  parameter Model.PathGeometry gp_recup_cold = Model.SetPathGeometry(geo_area = ga_recup_cold, L = L_recup, N_seg = N_seg);
  parameter Model.PathGeometry gp_recup_wall = Model.SetPathGeometry(geo_area = ga_recup_wall, L = L_recup, N_seg = N_seg);
  
  parameter Model.HeatExchangerConfig cfg_recup(
    cfg_hot(
      st_in    = st2, 
      st_out   = st3,
      geo_area = ga_recup_hot, 
      geo_path = gp_recup_hot, 
      N_ch     = N_ch_recup, 
      u        = 0,
      l_pitch  = l_pitch_recup,
      a_phi    = a_phi_recup
    ),
    cfg_cold( 
      st_in    = st6, 
      st_out   = st7, 
      geo_area = ga_recup_cold, 
      geo_path = gp_recup_cold, 
      N_ch     = N_ch_recup, 
      u        = 0,
      l_pitch  = l_pitch_recup,
      a_phi    = a_phi_recup
    ),
    cfg_fluid = cfg_recup.cfg_cold,
    cfg_gas   = cfg_recup.cfg_hot,
    cfg_wall(st_init = st_recup_wall, geo_area = ga_recup_wall, geo_wall = gp_recup_wall, rho_mcm = rho_wall * cp_wall, lambda = 200)
  );

  // ---- 3. ÉCHANGEUR HAUTE PRESSION ----
  parameter Modelica.SIunits.Radius r_channel_HX_HP= 1.5e-3;
  parameter Modelica.SIunits.Radius w_sd_HX_HP      = 2.3e-3;
  parameter Modelica.SIunits.Radius h_sd_HX_HP      = 4.17e-3;
  parameter Modelica.SIunits.Length t_ch_HX_HP      = 0.51e-3;
  
  parameter Modelica.SIunits.Length l_pitch_HX_HP= 12.3e-3 "pitch length";
  parameter Modelica.SIunits.Length a_phi_HX_HP  = 35      "pitch angle";

  parameter Modelica.SIunits.Length L_HX_HP         = 2.5;
  parameter Integer N_ch_HX_HP                      = 30000;

  parameter Model.AreaGeometry ga_HX_HP_hot  = Model.SetAreaGeometry_SemiCircle(r = r_channel_HX_HP);
  parameter Model.AreaGeometry ga_HX_HP_cold = Model.SetAreaGeometry_SemiCircle(r = r_channel_HX_HP);
  parameter Model.AreaGeometry ga_HX_HP_wall = Model.SetAreaGeometry_Wall(r = r_channel_HX_HP, w = w_sd_HX_HP, h = h_sd_HX_HP, p1 = t_ch_HX_HP);
  parameter Model.PathGeometry gp_HX_HP_hot  = Model.SetPathGeometry(geo_area = ga_HX_HP_hot, L = L_HX_HP, N_seg = N_seg);
  parameter Model.PathGeometry gp_HX_HP_cold = Model.SetPathGeometry(geo_area = ga_HX_HP_cold, L = L_HX_HP, N_seg = N_seg);
  parameter Model.PathGeometry gp_HX_HP_wall = Model.SetPathGeometry(geo_area = ga_HX_HP_wall, L = L_HX_HP, N_seg = N_seg);
  
  parameter Model.HeatExchangerConfig cfg_HX_HP(
    cfg_hot(
      st_in    = st_src_HX_HP_in, 
      st_out   = st_src_HX_HP_out, 
      geo_area = ga_HX_HP_hot, 
      geo_path = gp_HX_HP_hot, 
      N_ch     = N_ch_HX_HP, 
      u        = 0,
      l_pitch  = l_pitch_HX_HP,
      a_phi    = a_phi_HX_HP
    ),
    cfg_cold(
      st_in    = st3, 
      st_out   = st4, 
      geo_area = ga_HX_HP_cold, 
      geo_path = gp_HX_HP_cold, 
      N_ch     = N_ch_HX_HP, 
      u        = 0,
      l_pitch  = l_pitch_HX_HP,
      a_phi    = a_phi_HX_HP
    ),
    cfg_fluid = cfg_HX_HP.cfg_cold,
    cfg_gas   = cfg_HX_HP.cfg_hot,
    cfg_wall(st_init = st_HX_HP_wall, geo_area = ga_HX_HP_wall, geo_wall = gp_HX_HP_wall, rho_mcm = rho_wall * cp_wall, lambda = 200)
  );

  // ---- 4. TURBOMACHINES ----
  
  // Cartographie du Compresseur
  parameter Real tableEta_comp[5, 4]  = [0, 95, 100, 105; 1, 0.853, 0.837, 0.832; 2, 0.868, 0.857, 0.851; 3, 0.860, 0.850, 0.842; 4, 0.853, 0.839, 0.816];
  parameter Real tablePhic_comp[5, 4] = [0, 95, 100, 105; 1, 1.34E-4, 1.50E-4, 1.64E-4; 2, 1.37E-4, 1.53E-4, 1.68E-4; 3, 1.42E-4, 1.58E-4, 1.69E-4; 4, 1.45E-4, 1.61E-4, 1.71E-4];
//  parameter Real tablePR_comp[5, 4]   = [0, 95, 100, 105; 1, 1.967, 2.350, 2.785; 2, 1.915, 2.315, 2.681; 3, 1.810, 2.220, 2.524; 4, 1.654, 2.115, 2.359];
  parameter Real tablePR_comp[5, 4]   = [0, 95, 100, 105; 1, 4.467, 4.850, 5.285; 2, 4.415, 4.815, 5.181; 3, 4.310, 4.720, 5.024; 4, 4.154, 4.615, 4.859];

  // Cartographie de la Turbine
  parameter Real tablePhic_turb[5, 4] = [1, 37, 80, 100; 1.5, 7.10E-05, 7.10E-05, 7.10E-05; 2, 8.40E-05, 8.40E-05, 8.40E-05; 2.5, 8.70E-05, 8.70E-05, 8.70E-05; 3, 1.04E-04, 1.04E-04, 1.04E-04];
  parameter Real tableEta_turb[5, 4]  = [1, 37, 80, 100; 1.5, 0.57, 0.89, 0.81; 2, 0.46, 0.82, 0.88; 2.5, 0.41, 0.76, 0.85; 3, 0.38, 0.72, 0.82];
  
  parameter Model.TurbomachineryConfig cfg_comp(
    st_in  = st1,
    st_out = st2,
    N      = Ns_comp,
    T_nom  = 0,
    eta    = eta_comp
  );

  parameter Model.TurbomachineryConfig cfg_turb(
    st_in  = st4,
    st_out = st6,
    N      = Ns_turb,
    T_nom  = 0,
    eta    = eta_turb
  );  

end RecupBraytonCycleConfig_Motor;
