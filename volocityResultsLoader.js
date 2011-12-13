//Volocity output loader
// load the file from Fiji, then save as measurements. 
// then use it for the linking. 

importClass(Packages.javax.vecmath.Point3f);
importClass(Packages.java.util.Vector);
importPackage(Packages.util.opencsv);
importPackage(java.io);
importClass(Packages.javax.vecmath.Color3f);
importPackage(Packages.ij3d);
importPackage(Packages.customnode);

filepath = "/Users/miura/Dropbox/Mette/Tracks.csv";
filepath = 'C:\\Documents and Settings\\Kota Miura\\My Documents\\Downloads\\segmentation_z21-47t2-24_3.csv';
filepath = "/Users/miura/Dropbox/Mette/segmentation_z21-47t2-24_3.csv";
loadFile(filepath);

function loadFile(datapath){

	var reader = new CSVReader(new FileReader(datapath), ",", "\"");
	var ls = reader.readAll();
	var it = ls.iterator();
	var counter = 0;
	var currentTrajID = 1.0;
//	var atraj = Vector();
//	var timepoints = Vector();
//	var trajlist = Vector();
	rt = ResultsTable();
	while (it.hasNext()){
		var cA = it.next();
		if (counter == 1)
			headerA = cA;
		if (counter > 1){
			row = rt.getCounter(); 
			rt.incrementCounter();
			IJ.log("row " + row);
			rt.setValue(headerA[0], row, Integer.valueOf(cA[0]));
			rt.setValue(headerA[4], row, Double.valueOf(cA[4]));
			for (var i = 8; i < cA.length; i++){
				rt.setValue(headerA[i], row, Double.valueOf(cA[i]));
				IJ.log(Double.valueOf(cA[i]));
			}
						
/*				
			if ((currentTrajID - Double.valueOf(cA[1]) != 0) && (atraj.size() > 0)){
				IJ.log(Double.toString(currentTrajID) + cA[1]);
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
 */
		}
		counter++;
	}
	rt.show("Results");
	//return trajlist;
}


// trajectory as an object. 
function trajectoryObj(id, dotList, timepoints) {
	this.id = id;
	this.dotList = dotList;
	this.timepoints = timepoints; //a vector tith time points of the trajectory. 
}


/*
algorithm for dynamic plotting. 
for each time point, create gourp of mesh.
add the results to the time point (iterate this)
*/

//check if a time point is included in the trajectory. 
//(int, vector)
function CheckTimePointExists(thistimepoint, timepoints){
	var includesthistime = false;
	if ((timepoints.get(0) <= thistimepoint) && (timepoints.get(timepoints.size()-1) >= thistimepoint)){
		includesthistime = true;
	}
	return includesthistime;
}

function ReturnTrajectoryFragment(){
	
}