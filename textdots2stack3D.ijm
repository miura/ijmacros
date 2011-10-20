/**
 * 3D coordinates in text to 3D plot
 * Kota Miura (miura@embl.de)
 * 
 * 20111020 Script for Tomo modified for simpler data format. 
 */

print("\\Clear");
fullpathname = File.openDialog("Select a track File");
openedDirectory = File.getParent(fullpathname );
openedFile = File.getName(fullpathname );
tempstr = File.openAsString(fullpathname);
//tempstr = File.openAsString("");
linesA=split(tempstr,"\n");
xA = newArray(linesA.length);
yA = newArray(linesA.length);
zA = newArray(linesA.length);
for (i = 0; i < linesA.length; i ++){
	coordsA = split(linesA[i], ",");
	xA[i] = parseInt(coordsA[0]);
	yA[i] = parseInt(coordsA[1]);	
	zA[i] = parseInt(coordsA[2]);	
}
Array.getStatistics(xA, xmin, xmax, xmean, xsd);
Array.getStatistics(yA, ymin, ymax, ymean, ysd);
Array.getStatistics(zA, zmin, zmax, zmean, zsd);
print(" xmax ", xmax, " ymax ", ymax, " zmax ", zmax);
print(" xmin ", xmin, " ymin ", ymin, " zmin ", zmin);

title = "3Dplot";
Dialog.create("3D plotter");
Dialog.addString("stack name", title);
//Dialog.addChoice("Type:", newArray("8-bit", "16-bit", "32-bit", "RGB"));
Dialog.addNumber("Width:", xmax+1);
Dialog.addNumber("Height:", ymax+1);
Dialog.addNumber("Slices:", zmax+1);
//Dialog.addCheckbox("Ramp", true);
Dialog.show();
title = Dialog.getString();
width = Dialog.getNumber();
height = Dialog.getNumber();
slices = Dialog.getNumber();

Plot3Dstack(width, height, slices, xA, yA, zA, title);


//modified, no frame
function Plot3Dstack(ww, hh, zz, selectedxA, selectedyA, selectedzA, stacktitleS){
	dotsize = 1;
	newImage(stacktitleS, "8-bit Black", ww, hh, zz);
	op = "width="+ww+" height="+hh+" channels=1 slices="+zz+" frames=1 unit=pixel pixel_width=1.0000 pixel_height=1.0000 voxel_depth=1.0000 frame=[0 sec] origin=0,0";
	run("Properties...", op);
	setColor(255);
	for(i=0; i<selectedxA.length; i++) {
		zpos = round(selectedzA[i]);
		zpos = selectedzA[i];		
		if (zpos>zz) zpos=zz;
		//setSlice(zz+zpos+1);
		setSlice(zpos); //slice number starts from 1 in matlab		
//		drawOval(round(selectedxA[i])-radius, round(selectedyA[i])-radius, dotsize, dotsize);
		drawOval(round(selectedxA[i]), round(selectedyA[i]), dotsize, dotsize);
	}
}


//original
function Plot4Dstack(ww, hh, zz, tframes, selectedfA, selectedyA, selectedxA, selectedzA, stacktitleS){
	dotsize = 1;
	newImage(stacktitleS, "8-bit Black", ww, hh, zz*tframes);
	op = "width="+ww+" height="+hh+" channels=1 slices="+zz+" frames="+tframes+" unit=pixel pixel_width=1.0000 pixel_height=1.0000 voxel_depth=1.0000 frame=[0 sec] origin=0,0";
	run("Properties...", op);
	setColor(255);
	radius = round(dotsize/2);
	for(i=0; i<selectedfA.length; i++) {
		zpos = round(selectedzA[i]);
		if (zpos>zz) zpos=zz;
		setSlice(selectedfA[i]*zz+zpos+1);
//		drawOval(round(selectedxA[i])-radius, round(selectedyA[i])-radius, dotsize, dotsize);
		drawOval(round(selectedxA[i]), round(selectedyA[i]), dotsize, dotsize);
	}
}
