within Steps.Components;

model WaterCooler
  extends TwoPorts;
  
  import SI = Modelica.SIunits;

  parameter SI.Temperature T_cold_in;
  parameter Real pinch = 0.0; 
  
  PBMedia.ThermodynamicState medium_in "État thermodynamique à l'entrée";
  PBMedia.ThermodynamicState medium_out "État thermodynamique à la sortie";
    
equation
  
  medium_in = PBMedia.setState_phX(inlet.p, inStream(inlet.h_outflow));
  
  outlet.p = inlet.p;
  
  medium_out = PBMedia.setState_pTX(outlet.p, T_cold_in + pinch); 

  outlet.m_flow + inlet.m_flow = 0;  
  outlet.h_outflow = medium_out.h; 
  inlet.h_outflow = inStream(outlet.h_outflow);
  //outlet.T = medium_out.T; 
  
end WaterCooler;
