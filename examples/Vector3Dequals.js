importClass(Packages.org.apache.commons.math.geometry.euclidean.threed.Vector3D);
var cv3 = new Vector3D(0, 1, 3); 
var cv6 = new Vector3D(0, 2, 3);
if (cv3.equals(cv6)) IJ.log("same");
else IJ.log("not same"); 
