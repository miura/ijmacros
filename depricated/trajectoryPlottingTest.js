//test 3D path plotting using 3Dviewer@ImageJ
//Kota Miura (miura@embl.de)
//Dec. 5, 2011 

importClass(Packages.javax.vecmath.Point3f);
importClass(Packages.java.util.Vector);
importPackage(Packages.util.opencsv);
importPackage(java.io);
importClass(Packages.javax.vecmath.Color3f);
importPackage(Packages.ij3d);
importPackage(Packages.customnode);

ptvec = Vector();
ptvec.add(Point3f(1,3,4));
ptvec.add(Point3f(10,20,1));
ptvec.add(Point3f(30,40,5));

ptvec2 = Vector();
ptvec2.add(Point3f(-2,-3,-4));
ptvec2.add(Point3f(20,10,-5));
ptvec2.add(Point3f(50,20,5));

//imp = IJ.openImage(Prefs.getImagesURL() + "Spindly-GFP.zip");
univ = new Image3DUniverse();
univ.show();

imp = IJ.openImage('/Users/miura/Desktop/s1short.tif');
c = univ.addVoltex(imp); 
tl = univ.getTimeline();

col = Color3f(0, 1.0, 0);
col2 = Color3f(1.0, 0, 0);

filepath = "/Users/miura/Dropbox/Mette/Tracks.csv";

tracks = CustomMultiMesh();

var reader = new CSVReader(new FileReader(filepath), ",");
var ls = reader.readAll();
var it = ls.iterator();
var counter = 0;
var currentTrajID = 1.0;
cvec = Vector();
while (it.hasNext()){
	var cA = it.next();
	if (counter != 0){
		if ((currentTrajID - Double.valueOf(cA[1]) != 0) && (cvec.size() > 0)){
			IJ.log(Double.toString(currentTrajID) + cA[1]);
			clm0 = CustomLineMesh(cvec, CustomLineMesh.CONTINUOUS, col, 0);
			tracks.add(clm0);
			currentTrajID = Double.valueOf(cA[1]);
			//cvec.clear();
			cvec = Vector();
		}
 		//cvec.add(Point3f(Double.valueOf(cA[3]),Double.valueOf(cA[4]),Double.valueOf(cA[5])));
 		cvec.add(Point3f(Double.valueOf(cA[6]),Double.valueOf(cA[7]),Double.valueOf(cA[8])));   
	}
	counter++;
}
//clm0 = CustomLineMesh(cvec, CustomLineMesh.CONTINUOUS, col, 0);
//tracks.add(clm0);
         



//tl.next();

//univ.showTimepoint(2) 


//univ.addLineMesh(ptvec, col, "line 00000", true);

clm1 = CustomLineMesh(ptvec, CustomLineMesh.CONTINUOUS, col, 0);
clm2 = CustomLineMesh(ptvec2, CustomLineMesh.CONTINUOUS, col2, 0);
clmm = CustomMultiMesh();
clmm.add(clm1);
clmm.add(clm2);

//c2 = univ.addCustomMesh(clmm, "test2");
//c2.setShowAllTimepoints(true);

c3 = univ.addCustomMesh(tracks, "track");
c3.setShowAllTimepoints(true);
//timepoint = 2;
//c2 = ContentCreator.createContent(clmm, "test2", timepoint);
//univ.addContent(c2);

