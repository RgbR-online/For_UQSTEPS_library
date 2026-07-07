within Steps.Components;



model KimCorrelations  "Correlation constants in Kim [2012]"
  import MyUtil = Steps.Utilities.Util;
  
  input Modelica.SIunits.Length pitch = 24.6 * 1e-3;
  input Modelica.SIunits.Diameter d_h = 0.922 * 1e-3;  
  input Modelica.SIunits.Angle phi = 0.0 "unit rad";
  
	output Real a;
	output Real b;
	output Real c;	
	output Real d;
	
	record KimCorrCoe "Record for Kim correlation coefficients, aligns with the struct definition in C"
  
    Real a;
    Real b;
    Real c;
    Real d;
  
  end KimCorrCoe;
	
	protected
    Modelica.Blocks.Types.ExternalCombiTable1D table_4a_a = Modelica.Blocks.Types.ExternalCombiTable1D(tableName = "4a_a", fileName = Modelica.Utilities.Files.loadResource("modelica://Steps/Resources/Data/kim_2012.txt"), table = fill(0.0, 9, 2), smoothness = Modelica.Blocks.Types.Smoothness.LinearSegments, columns = 2:2) "Table 4a - column a in Kim[2012] for pitch=24.6, dh=0.922 (dc=1.3 mm))";

  Modelica.Blocks.Types.ExternalCombiTable1D table_4a_b = Modelica.Blocks.Types.ExternalCombiTable1D(tableName = "4a_b", fileName = Modelica.Utilities.Files.loadResource("modelica://Steps/Resources/Data/kim_2012.txt"), table = fill(0.0, 9, 2), smoothness = Modelica.Blocks.Types.Smoothness.LinearSegments, columns = 2:2) "Table 4a - column b in Kim[2012] for pitch=12.3, dh=0.922 (dc=1.3 mm))";
  
  Modelica.Blocks.Types.ExternalCombiTable1D table_4b_a = Modelica.Blocks.Types.ExternalCombiTable1D(tableName = "4b_a", fileName = Modelica.Utilities.Files.loadResource("modelica://Steps/Resources/Data/kim_2012.txt"), table = fill(0.0, 9, 2), smoothness = Modelica.Blocks.Types.Smoothness.LinearSegments, columns = 2:2) "Table 4b - column a in Kim[2012] for pitch=24.6, dh=1.222 (dc=1.3 mm))";  
  
  Modelica.Blocks.Types.ExternalCombiTable1D table_4b_b = Modelica.Blocks.Types.ExternalCombiTable1D(tableName = "4b_b", fileName = Modelica.Utilities.Files.loadResource("modelica://Steps/Resources/Data/kim_2012.txt"), table = fill(0.0, 9, 2), smoothness = Modelica.Blocks.Types.Smoothness.LinearSegments, columns = 2:2) "Table 4b - column b default table";  
  
  Modelica.Blocks.Types.ExternalCombiTable1D table_4c_a = Modelica.Blocks.Types.ExternalCombiTable1D(tableName = "4c_a", fileName = Modelica.Utilities.Files.loadResource("modelica://Steps/Resources/Data/kim_2012.txt"), table = fill(0.0, 9, 2), smoothness = Modelica.Blocks.Types.Smoothness.LinearSegments, columns = 2:2) "Table 4c - column a in Kim[2012] for pitch=24.6, dh=0.922 (dc=1.3 mm))";

  Modelica.Blocks.Types.ExternalCombiTable1D table_4c_b = Modelica.Blocks.Types.ExternalCombiTable1D(tableName = "4c_b", fileName = Modelica.Utilities.Files.loadResource("modelica://Steps/Resources/Data/kim_2012.txt"), table = fill(0.0, 9, 2), smoothness = Modelica.Blocks.Types.Smoothness.LinearSegments, columns = 2:2) "Table 4c - column b in Kim[2012] for pitch=12.3, dh=0.922 (dc=1.3 mm))";  

  Modelica.Blocks.Types.ExternalCombiTable1D table_5a_c = Modelica.Blocks.Types.ExternalCombiTable1D(tableName = "5a_c", fileName = Modelica.Utilities.Files.loadResource("modelica://Steps/Resources/Data/kim_2012.txt"), table = fill(0.0, 9, 2), smoothness = Modelica.Blocks.Types.Smoothness.LinearSegments, columns = 2:2) "Table 5a - column c in Kim[2012] for pitch=24.6, dh=0.922 (dc=1.3 mm))";

  Modelica.Blocks.Types.ExternalCombiTable1D table_5a_d = Modelica.Blocks.Types.ExternalCombiTable1D(tableName = "5a_d", fileName = Modelica.Utilities.Files.loadResource("modelica://Steps/Resources/Data/kim_2012.txt"), table = fill(0.0, 9, 2), smoothness = Modelica.Blocks.Types.Smoothness.LinearSegments, columns = 2:2) "Table 5a - column d in Kim[2012] for pitch=12.3, dh=0.922 (dc=1.3 mm))";
  
  Modelica.Blocks.Types.ExternalCombiTable1D table_5b_c = Modelica.Blocks.Types.ExternalCombiTable1D(tableName = "5b_c", fileName = Modelica.Utilities.Files.loadResource("modelica://Steps/Resources/Data/kim_2012.txt"), table = fill(0.0, 9, 2), smoothness = Modelica.Blocks.Types.Smoothness.LinearSegments, columns = 2:2) "Table 5b - column c in Kim[2012] for pitch=24.6, dh=1.222 (dc=1.3 mm))";
  
  Modelica.Blocks.Types.ExternalCombiTable1D table_5b_d = Modelica.Blocks.Types.ExternalCombiTable1D(tableName = "5b_d", fileName = Modelica.Utilities.Files.loadResource("modelica://Steps/Resources/Data/kim_2012.txt"), table = fill(0.0, 9, 2), smoothness = Modelica.Blocks.Types.Smoothness.LinearSegments, columns = 2:2) "Table 5b - column d default table";
  
  Modelica.Blocks.Types.ExternalCombiTable1D table_5c_c = Modelica.Blocks.Types.ExternalCombiTable1D(tableName = "5c_c", fileName = Modelica.Utilities.Files.loadResource("modelica://Steps/Resources/Data/kim_2012.txt"), table = fill(0.0, 9, 2), smoothness = Modelica.Blocks.Types.Smoothness.LinearSegments, columns = 2:2) "Table 5c - column c in Kim[2012] for pitch=24.6, dh=0.922 (dc=1.3 mm))";

  Modelica.Blocks.Types.ExternalCombiTable1D table_5c_d = Modelica.Blocks.Types.ExternalCombiTable1D(tableName = "5c_d", fileName = Modelica.Utilities.Files.loadResource("modelica://Steps/Resources/Data/kim_2012.txt"), table = fill(0.0, 9, 2), smoothness = Modelica.Blocks.Types.Smoothness.LinearSegments, columns = 2:2) "Table 5c - column d in Kim[2012] for pitch=12.3, dh=0.922 (dc=1.3 mm))";
    
  Modelica.Blocks.Types.ExternalCombiTable1D table_a = Modelica.Blocks.Types.ExternalCombiTable1D(tableName = "4d_a", fileName = Modelica.Utilities.Files.loadResource("modelica://Steps/Resources/Data/kim_2012.txt"), table = fill(0.0, 9, 2), smoothness = Modelica.Blocks.Types.Smoothness.LinearSegments, columns = 2:2);
  
  Modelica.Blocks.Types.ExternalCombiTable1D table_b = Modelica.Blocks.Types.ExternalCombiTable1D(tableName = "4d_b", fileName = Modelica.Utilities.Files.loadResource("modelica://Steps/Resources/Data/kim_2012.txt"), table = fill(0.0, 9, 2), smoothness = Modelica.Blocks.Types.Smoothness.LinearSegments, columns = 2:2);
  
  Modelica.Blocks.Types.ExternalCombiTable1D table_c = Modelica.Blocks.Types.ExternalCombiTable1D(tableName = "5d_c", fileName = Modelica.Utilities.Files.loadResource("modelica://Steps/Resources/Data/kim_2012.txt"), table = fill(0.0, 9, 2), smoothness = Modelica.Blocks.Types.Smoothness.LinearSegments, columns = 2:2);
  
  Modelica.Blocks.Types.ExternalCombiTable1D table_d = Modelica.Blocks.Types.ExternalCombiTable1D(tableName = "5d_d", fileName = Modelica.Utilities.Files.loadResource("modelica://Steps/Resources/Data/kim_2012.txt"), table = fill(0.0, 9, 2), smoothness = Modelica.Blocks.Types.Smoothness.LinearSegments, columns = 2:2);

algorithm
    // determine fitting constant by pitch and hydraulic diameter directly
    if(abs(pitch - 12.3e-3) <= abs(pitch - 24.6e-3)) then //close to pitch = 12.3
      
      if(abs(d_h - 0.922e-3) <= abs(d_h - 1.222e-3)) then // close to d_h 0.922
        a := Modelica.Blocks.Tables.Internal.getTable1DValue(table_4b_a, icol = 1, u = Modelica.SIunits.Conversions.to_deg(phi));
        b := Modelica.Blocks.Tables.Internal.getTable1DValue(table_4b_b, icol = 1, u = Modelica.SIunits.Conversions.to_deg(phi));
        c := Modelica.Blocks.Tables.Internal.getTable1DValue(table_5b_c, icol = 1, u = Modelica.SIunits.Conversions.to_deg(phi));
        d := Modelica.Blocks.Tables.Internal.getTable1DValue(table_5b_d, icol = 1, u = Modelica.SIunits.Conversions.to_deg(phi));
      else
        //default value - table_4b, 5b dual branch
        a := Modelica.Blocks.Tables.Internal.getTable1DValue(table_4b_a, icol = 1, u = Modelica.SIunits.Conversions.to_deg(phi));
        b := Modelica.Blocks.Tables.Internal.getTable1DValue(table_4b_b, icol = 1, u = Modelica.SIunits.Conversions.to_deg(phi));
        c := Modelica.Blocks.Tables.Internal.getTable1DValue(table_5b_c, icol = 1, u = Modelica.SIunits.Conversions.to_deg(phi));
        d := Modelica.Blocks.Tables.Internal.getTable1DValue(table_5b_d, icol = 1, u = Modelica.SIunits.Conversions.to_deg(phi));        
      end if;
      
    else // close to pitch = 24.6
    
      if(abs(d_h - 0.922e-3) <= abs(d_h - 1.222e-3)) then
        a := Modelica.Blocks.Tables.Internal.getTable1DValue(table_4a_a, icol = 1, u = Modelica.SIunits.Conversions.to_deg(phi));
        b := Modelica.Blocks.Tables.Internal.getTable1DValue(table_4a_b, icol = 1, u = Modelica.SIunits.Conversions.to_deg(phi));
        c := Modelica.Blocks.Tables.Internal.getTable1DValue(table_5a_c, icol = 1, u = Modelica.SIunits.Conversions.to_deg(phi));
        d := Modelica.Blocks.Tables.Internal.getTable1DValue(table_5a_d, icol = 1, u = Modelica.SIunits.Conversions.to_deg(phi));
      else
        a := Modelica.Blocks.Tables.Internal.getTable1DValue(table_4c_a, icol = 1, u = Modelica.SIunits.Conversions.to_deg(phi));
        b := Modelica.Blocks.Tables.Internal.getTable1DValue(table_4c_b, icol = 1, u = Modelica.SIunits.Conversions.to_deg(phi));
        c := Modelica.Blocks.Tables.Internal.getTable1DValue(table_5c_c, icol = 1, u = Modelica.SIunits.Conversions.to_deg(phi));
        d := Modelica.Blocks.Tables.Internal.getTable1DValue(table_5c_d, icol = 1, u = Modelica.SIunits.Conversions.to_deg(phi));
      end if;       
      
    end if;

end KimCorrelations;
