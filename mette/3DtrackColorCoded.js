// imorting trackdata and plot in 3Dviewer, no time series
// tracks are color coded. 
// Kota Miura
//20111219

importClass(Packages.java.util.Vector);
importPackage(Packages.util.opencsv);
importPackage(java.io);
importClass(Packages.javax.vecmath.Color3f);
importPackage(Packages.ij3d);
importClass(Packages.customnode.CustomTriangleMesh);
importClass(Packages.customnode.CustomMesh);
importClass(Packages.customnode.CustomMultiMesh);
importClass(Packages.customnode.CustomPointMesh);
importClass(Packages.customnode.CustomLineMesh);
importClass(Packages.javax.vecmath.Point3f);

filepath = "/Users/miura/Dropbox/Mette/Tracks.csv";
filepath = "/Users/miura/Dropbox/Mette/data27_cut0_1_6_6cc.csv";

timestart = 0; timeend = 23;
tList = loadFile(filepath);
univ = new Image3DUniverse();
univ.show();

col = Color3f(0, 1.0, 0.5);
col2 = Color3f(1.0, 0, 0);
colw = Color3f(1.0, 1.0, 1.0);

 PlotTimeColorCodedTrack(timestart, timeend, tList, univ);

//check if a time point is included in the trajectory. 
//(int, vector)
function CheckTimePointExists(thistimepoint, timepoints){
	var includesthistime = false;
	if ((timepoints.get(0) <= thistimepoint) && (timepoints.get(timepoints.size()-1) >= thistimepoint)){
		includesthistime = true;
	}
	return includesthistime;
}

function ReturnIndexFromTime(srctime, timepoints){
	var index = -1;
	for (var i = 0; i < timepoints.size(); i++){
		if (srctime == timepoints.get(i))
			index = i;
	}
	return index;
}

// trajectory as an object. 
function trajectoryObj(id, dotList, timepoints) {
	this.id = id;
	this.dotList = dotList;
	this.timepoints = timepoints; //a vector tith time points of the trajectory. 
}
 
function loadFile(datapath){

	var reader = new CSVReader(new FileReader(datapath), ",");
	var ls = reader.readAll();
	var it = ls.iterator();
	var counter = 0;
	var currentTrajID = 1.0;
	var atraj = Vector();
	var timepoints = Vector();
	var trajlist = Vector();
	while (it.hasNext()){
		var cA = it.next();
		if (counter != 0){
			if ((currentTrajID - Double.valueOf(cA[1]) != 0) && (atraj.size() > 0)){
				//IJ.log(Double.toString(currentTrajID) + cA[1]);
				var atrajObj = new trajectoryObj(currentTrajID, atraj, timepoints);
				trajlist.add(atrajObj);
				currentTrajID = Double.valueOf(cA[1]);
				//cvec.clear();
				atraj = Vector();
				timepoints = Vector();
			}
			// pixel positions
 			//cvec.add(Point3f(Double.valueOf(cA[3]),Double.valueOf(cA[4]),Double.valueOf(cA[5])));
 			// scaled positions
 			atraj.add(Point3f(Double.valueOf(cA[6]),Double.valueOf(cA[7]),Double.valueOf(cA[8]))); 
 			timepoints.add(Double.valueOf(cA[2]));  
		}
		counter++;
	}
	return trajlist;
}

//20111219 plot color coded track using tube-mesh
function PlotTimeColorCodedTrack(timestart, timeend, tList, univ){
for (var i = timestart; i < timeend-1; i++){
	var tubes = Vector();
	for (var j = 0; j < tList.size(); j++) {
		var curtraj = tList.get(j);
		if (CheckTimePointExists(i, curtraj.timepoints) && CheckTimePointExists(i+1, curtraj.timepoints)){
			var dt = curtraj.dotList;
			var pathextract = Vector();
			pathextract.addAll(curtraj.dotList);
			var timeextract = Vector();
			timeextract.addAll(curtraj.timepoints);
			var ind = timeextract.indexOf(i);
			var spoint = pathextract.get(ind);
			var epoint = pathextract.get(ind+1);			
			var xA = javaArray(spoint.x, epoint.x);
			var yA = javaArray(spoint.y, epoint.y);
			var zA = javaArray(spoint.z, epoint.z);
			var rA = javaArray(0.2, 0.2);					
			var tube = Mesh_Maker.createTube(xA, yA, zA, rA, 24, false);
			tubes.addAll(tube);
			IJ.log("index"+j + " frame" + i);
		}
	}
	var cR = i/(timeend -1 - timestart);
	var cB = 1 - cR; 
	var csp = CustomTriangleMesh(tubes, Color3f(cR, 0.6, cB), 0.0);
//	var ccs = ContentCreator.createContent(csp, "tubetime" + Integer.toString(i), i-timestart);
	var ccs = ContentCreator.createContent(csp, "tubetime" + Integer.toString(i), 0);

	univ.addContent(ccs);
}	
}

//geenrates a java array from two doubles
function javaArray(sp, ep){
	ja = new java.lang.reflect.Array.newInstance(java.lang.Double.TYPE, 2);
	ja[0] = sp;
	ja[1] = ep;
	return ja;
}