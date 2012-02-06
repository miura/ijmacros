// An example of overlay function in ImageJ / Fiji.
// Kota Miura (miura@embl.de) 
//
// for using Arrows, use commented out lines. 

overlayLine(10, 10, 40, 40);
overlayLine(40, 40, 10, 70);

function overlayLine(x1, y1, x2, y2){
	importClass(Packages.ij.gui.Overlay);
	importClass(Packages.java.awt.Color);
	imp = IJ.getImage();
//roi1 = Arrow( 110, 245, 111, 246);
	roi1 = Line(x1, y1, x2, y2);
//roi1.setWidth(1.5);
//roi1.setHeadSize(3);
	imp.setRoi(roi1);
	overlay = imp.getOverlay();
	if (overlay != null)
		overlay.add(roi1);
	else
		overlay = Overlay(roi1);
	red = Color(1, 0, 0);
	overlay.setStrokeColor(red); 
	imp.setOverlay(overlay);
	imp.updateAndDraw() ;

//IJ.log("head " + roi1.getDefaultHeadSize());
//IJ.log("head " + roi1.getDefaultWidth());
}


