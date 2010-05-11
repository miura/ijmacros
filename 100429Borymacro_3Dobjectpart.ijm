macro "test 3D dot detection"{
	GetDotCoordinatesV2();
}

var res3DobjA = newArray(701); //storing 3D obejct counter one dot would occupy 7 indices
/*
0 number of dots detected
1 volume
2 surface area	(surface area is not really reliable with ImageJ plugin, maybe is OK in FIJI)
3 total intensity
4 x coordinate
5 y coordinate
6 z coordinate

1- 7 should be then iterated for number of dots detected. 
*/

// for detecting dots in single frame
//works with binarized image
function GetDotCoordinatesV2(){
	wintitle = getTitle();
	//should check scale here. 
	//following option is specific to Fiji
	  //run("3D OC Options", "volume surface nb_of_obj._voxels nb_of_surf._voxels integrated_density mean_gray_value std_dev_gray_value median_gray_value minimum_gray_value maximum_gray_value centroid mean_distance_to_surface std_dev_distance_to_surface median_distance_to_surface centre_of_mass bounding_box dots_size=5 font_size=10 store_results_within_a_table_named_after_the_image_(macro_friendly) redirect_to=none");
	//below is for Fiji pluign
	  //run("3D Objects Counter", "threshold=128 slice=1 min.=1 max.=480000 statistics");
	//below is for ImageJ plugin
	run("Object Counter3D", "threshold=128 slice=1 min=10 max=480000 new_results dot=3 font=12");
	resultwin = "Results from " + wintitle; //ImageJ
	//resultwin = "Statistics for " + wintitle; //Fiji
	selectWindow(resultwin);
	//print(getInfo("window.contents"));
	tabletext = getInfo("window.contents");
	tableA = split(tabletext, "\n");
	print("detected dot number:"+tableA.length-1);
	for (i=0; i<tableA.length; i++) print(tableA[i]);
	res3DobjA[0] = tableA.length-1;
	for (i=1; i<tableA.length; i++){
		paraA=split(tableA[i]);
		for (j=0; j<6; j++) res3DobjA[(i-1)*6+j+1] = paraA[j+1];
	}
	for(i=0; i<res3DobjA[0]*6+1; i++) print(res3DobjA[i]);
}	

/*	
	selectedline = 1; //default, only one dot detected.
	if (tableA.length > 2) {
		print("More than two dots detected in "+wintitle);
		volumeA = newArray(tableA.length);
		for (i=1; i<tableA.length; i++) {
			templineA = split(tableA[i], "\t");
			volumeA[i] = templineA[1];
		}
		volume =0; 
		index = 0;
		for (i=1; i<volumeA.length; i++){
			if (volumeA[i] > volume) {
				volume = volumeA[i];
				index = i;
			}
		}
		selectedline = index; 
		print("   ... Index selected:"+selectedline);
	}
	if (tableA.length == 1) {	//when no dot detectd, fill -1 for return values
		pos3DA[0] = -1; //x
		pos3DA[1] = -1; //y
		pos3DA[2] = -1; //z

	} else {
		lineA = split(tableA[selectedline], "\t");
			//pos3DA[0] = lineA[4]; //x  these are cases when using ImageJ
			//pos3DA[1] = lineA[5]; //y
			//pos3DA[2] = lineA[6]; //z

		pos3DA[0] = lineA[11]; //x these are cases when using Fiji 
		pos3DA[1] = lineA[12]; //y
		pos3DA[2] = lineA[13]; //z

	}
	return (tableA.length-1); //number of dots detected.
*/	
}
