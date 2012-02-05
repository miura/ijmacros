// 090906 -
// for opening specific channel in LIF dataset. 
// 090912 add nucID stackker

/*
macro "test path names"{
	tifstackpath = getDirectory("Tifstack DIr?");
	genename= File.getName(File.getParent(tifstackpath));
	print(genename);
	
}
*/


macro "NucID image stacker"{	
	tifstackpath = getDirectory("Tifstack DIr?");
	NucIDstackerCore(tifstackpath);
}

macro "batch NucID Stacker"{
	q = File.separator; //090912
	filelist = File.openAsString("");
	filelistA= split(filelist ,"\n") ; //first line is column label
	rootdir = getDirectory("Choose a work space directory where resulting files are");
	lastGeneName ="dummy";	//for keeping the genename
	for (i =1; i<filelistA.length; i++){
		linecontentA=split(filelistA[i] ,"\t");
		genename=linecontentA[1];
		if (genename != lastGeneName) {
			genepath = rootdir + q + genename + q;
			tifstackpath = rootdir + q + genename + q + "tifStack"+q;
			NucIDstackerCore(tifstackpath);
			saveAs("Tiff", rootdir + getTitle());
			lastGeneName = genename;
			close();
		}
	}	


}


function NucIDstackerCore(tifstackpath){
	tiflistA = getFileList(tifstackpath);
	counter=0;
	for(i=0; i<tiflistA.length; i++){
		if (startsWith(tiflistA[i], "NucID_")) counter++;
	}
	slicetotal=counter;
	genename= File.getName(File.getParent(tifstackpath));
	counter=0;
	setBatchMode(true);
	for(i=0; i<tiflistA.length; i++){
		if (startsWith(tiflistA[i], "NucID_")) {
			fullpath = tifstackpath + tiflistA[i];
			open(fullpath);
			//open("C:\\dropbox\\My Dropbox\\Ritsuko\\090728\\102497-10.lif - 7 - C=1.tif");
			currenttitle = getTitle();
			nucIDID = getImageID();
			if (counter==0) {
				getDimensions(width, height, channels, slices, frames);
				newImage(genename + "_NucID.tif", "8-bit black", width, height, 1);
				stackID = getImageID();
			} else{
				selectImage(stackID);
				run("Add Slice");
			}
			selectImage(nucIDID);	
			run("Copy");
			close();
			selectImage(stackID);
			run("Paste");
			setMetadata("Label", currenttitle);
			counter++;			
		}
	}
	setBatchMode("exit and display");
}


macro "-"{}

macro "getting lif info test"{
	run("Bio-Formats Macro Extensions");
	id = File.openDialog("Choose a file");
	Ext.setId(id);
	Ext.getSeriesCount(seriesCount);
	Ext.getCurrentFile(file);
	print("File:"+ file);
	print("series number" + seriesCount);
	print("****************** ");

	for (s=0; s<seriesCount; s++) {
	  Ext.setSeries(s);
	Ext.getSeriesName(seriesName);
	Ext.getImageCount(n);
	Ext.getDimensionOrder(dimOrder);
	  Ext.getSizeX(sizeX);
	  Ext.getSizeY(sizeY);
	  Ext.getSizeZ(sizeZ);
	  Ext.getSizeC(sizeC);
	  Ext.getSizeT(sizeT);	
/* parts to be tested for getting metadata
*/
//	following three lines were for Ritsuko's data
//	XscaleKey = seriesName+ "- Sequential Setting 2 - dblVoxelX - Voxel-Width";
//	YscaleKey = seriesName+ " - Sequential Setting 2 - dblVoxelY - Voxel-Height";
//	ZscaleKey = seriesName+ " - Sequential Setting 2 - dblVoxelZ - Voxel-Depth";

	XscaleKey = "HardwareSetting|ScannerSettingRecord|dblVoxelX 1";
	YscaleKey = "HardwareSetting|ScannerSettingRecord|dblVoxelY 1";
	ZscaleKey = "HardwareSetting|ScannerSettingRecord|dblVoxelZ 1";

	//XscaleKey = "Sequence_001/gfp2 HardwareSetting|ScannerSettingRecord|dblSizeX 1";
	//XscaleKey = "OME - ";
	
	key = "HardwareSetting|ScannerSettingRecord|dblVoxelX 1";
	//print(getInfo(key));
	//print("Metadata : " + collected);
	testkey = "key";
	testval="";
	Ext.getMetadataValue(testkey, testval);
	print("TESTVAL = " + testval);
	
	Ext.getMetadataValue(XscaleKey, xscale);
	Ext.getMetadataValue(YscaleKey, yscale);
	Ext.getMetadataValue(ZscaleKey, zscale);

	print(seriesName);
	print("Series #" + s + ": image resolution is " + sizeX + " x " + sizeY);
	print("image number "+n);
	print(dimOrder);
	print("Focal plane count = " + sizeZ);
	print("Channel count = " + sizeC);
	print("Time point count = " + sizeT);
	
	print("X pixel width = " +xscale);
	print("Y pixel width = " +yscale);
	print("Z pixel width = " +zscale);
	}
	Ext.close();
}

//Ext.openImage(title, no)

//working  maybe memory flashing problem, but not sure. 
function OpenLIFSeriesOneChannel(id, name, seriesNum, ch){
	run("Bio-Formats Macro Extensions");
	Ext.setId(id);
	Ext.setSeries(seriesNum);
	Ext.getSizeZ(sizeZ);
	Ext.getSizeC(sizeC);
	newname = name+"_"+seriesNum+"_ch"+ch+".tif";
	setBatchMode(true);
	for (i=0; i<sizeZ; i++){
		currentZch0 = i*sizeC;
		Ext.openImage("plane"+currentZch0, currentZch0+ch);
		if (i==0)
			stackID=getImageID();
		else	{
			run("Copy");
			close;
			selectImage(stackID);
			run("Add Slice");
			run("Paste");
		}
	}
	rename(newname);
	setBatchMode(false);
	Ext.close();		
}

//working
macro "test open ch0 and ch1"{
	seriesnumber = getNumber("series num", 0);
	ch01opner(seriesnumber);
}

function ch01opner(seriesnumber){
	path = File.openDialog("Select a File");
	name = File.getName(path);
	
	dir = File.getParent(path);
	OpenLIFSeriesOneChannel(path, name, seriesnumber, 0);
	savepath = dir + "\\"+getTitle();
	print(savepath);
	OpenLIFSeriesOneChannel(path, name, seriesnumber, 1);
	savepath = dir  + "\\"+ getTitle();
	print(savepath);

}

macro "dev. auto ROI detector from LIF"{
	path = File.openDialog("Select a LIF File");
	name = File.getName(path);
	dir = File.getParent(path);	
	seriesNum = getNumber("series No. ?", 0);
	DAPIch = getNumber("DAPI ch=?", 0);
	FISHch = getNumber("FISH ch=?", 1);

	OpenLIFSeriesOneChannel(path, name, seriesNum, DAPIch);
	G_GID = getImageID();

	OpenLIFSeriesOneChannel(path, name, seriesNum, FISHch);
	G_RID = getImageID(); 
}
