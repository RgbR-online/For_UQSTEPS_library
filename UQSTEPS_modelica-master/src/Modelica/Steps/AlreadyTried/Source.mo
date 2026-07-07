within Steps.AlreadyTried;

model Source 
  "EndPoint for component test with fixed inlet/outlet temperature and pressure"
  //extends Steps.Components.TwoPorts;
  import CP = Steps.Utilities.CoolProp;
  import Modelica.SIunits.Conversions.{from_bar,from_degC};
  import Modelica.Blocks.Interfaces.RealInput;
  replaceable package PBMedia = Steps.Media.SCO2;
  // fixed outlet temperautre and pressure
  parameter Modelica.SIunits.AbsolutePressure p_outlet = 9*1e6;
  parameter Modelica.SIunits.Temperature T_outlet = from_degC(400);
  parameter Modelica.SIunits.Enthalpy h_outlet = CP.PropsSI("H", "P", p_outlet, "T", T_outlet, PBMedia.mediumName);
  // fixed mass flow
  parameter Modelica.SIunits.MassFlowRate mdot_init = 8.3;
  parameter Boolean fix_flow = true "if use this component as flow boundary condition";
  parameter Boolean fix_state = true "if use this component as state boundary condition";
  Modelica.SIunits.Temperature T;
  replaceable Steps.Interfaces.PBFluidPort_b outlet(redeclare package Medium = PBMedia, p.start = p_outlet, h_outflow.start = h_outlet) "Outlet port, next component";
equation
//determine the boundary condition
  if fix_flow then
    outlet.m_flow = -mdot_init;
    outlet.p = p_outlet;
  end if;
  if fix_state then
    T = T_outlet;
    outlet.h_outflow = CP.PropsSI("H", "P", outlet.p, "T", T, PBMedia.mediumName);
  else       
    T = CP.PropsSI("T", "P", outlet.p, "H", outlet.h_outflow, PBMedia.mediumName);
  end if;
end Source;
