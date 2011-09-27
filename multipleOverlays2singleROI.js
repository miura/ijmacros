importClass(Packages.ij.gui.ShapeRoi);

imp = IJ.getImage();
overl = imp.getOverlay();
combroi = combineROI(overl);
overl.clear();
overl.add(combroi);
combroi.setStrokeWidth(1);
combroi.setStrokeColor(java.awt.Color.RED); 

function combineROI(over){
	var s1 = null;
	var s2 = null;
	for (var i =0; i <over.size(); i++){
    		var aroi = overl.get(i);
   		IJ.log("accessing overlay "+ i + "th");
    		if (aroi != null){
    			if (s1 == null)
     				s1 = ShapeRoi(aroi);
     			else {
       				s2 = ShapeRoi(aroi);
       				s1 = s1.or(s2);
     			}
		} else {
    			IJ.log("...object " + "not detected");
   		}
	}
  return s1;
}