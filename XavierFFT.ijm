orgID = getImageID();
run("Duplicate...", "title=FFTseries.tif");
stackID = getImageID();

// following three parameters could be adjusted later
stepsize = 10;
fftmax = 200
fftmin = 10;

steps = floor((fftmax - fftmin) / stepsize);

setBatchMode(true);
for (i = 0; i < steps; i++){
	op = "filter_large=" + fftmax + " filter_small="+ fftmin + i * stepsize +" suppress=None tolerance=5 autoscale saturate";
	if (i == 0 ){
		selectImage(stackID);
		run("Bandpass Filter...", op);
	} else {
		selectImage(orgID);
		run("Select All");
		run("Copy");
		selectImage(stackID);
		run("Add Slice");
		run("Paste");
		run("Bandpass Filter...", op);				
	}
	setMetadata("Label", "min="+fftmin + i * stepsize);
}
setBatchMode("exit and display");

