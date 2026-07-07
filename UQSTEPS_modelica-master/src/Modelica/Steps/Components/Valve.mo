within Steps.Components;

model Valve  "This class is basic valve"
  extends TwoPorts;
  
  parameter Modelica.SIunits.AbsolutePressure p_outlet "fixed outlet pressure";
  
  PBMedia.ThermodynamicState medium_in "État thermodynamique à l'entrée";
  PBMedia.ThermodynamicState medium_out "État thermodynamique à la sortie";
equation
  medium_in = PBMedia.setState_phX(inlet.p, inStream(inlet.h_outflow));
  medium_out = PBMedia.setState_phX(outlet.p, inStream(inlet.h_outflow));
  
  outlet.m_flow + inlet.m_flow = 0;
  outlet.h_outflow = inStream(inlet.h_outflow);
  outlet.p = p_outlet;
  inlet.h_outflow = inStream(outlet.h_outflow);

  //outlet.T = medium_out.T;
end Valve;
