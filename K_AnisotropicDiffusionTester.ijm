//K_AnisotropicDiffusionTester.ijm
// Kota Miura (miura@embl.de)
//
// explore parameter space for checking filtering results. 
// number: number of iterations
// smoothings: smoothings per iteration
// keep: keep each iteration
// a1: Diffusion limiter along minimal variations
// a2: Diffusion limiter along maximal variations
// dt: timestep
// edge: edge threshold height
originalID = getImageID();
run("Duplicate...", "title=testFiltering");
duporigID = getImageID();
run("Select All");
run("Copy");
vmin = 1;
vmax = 20;
vstep = 2;
run("Colors...", "foreground=white background=black selection=yellow");
setBatchMode(true);
for (i = vmin; i < vmax; i+=vstep){
	selectImage(duporigID);
	if (i == vmin){
		run("Duplicate...", "title=orginal");
		refID = getImageID();
	}
	selectImage(refID);
	paratext = "edge=" + i;
	op = "number=20 smoothings=1 keep=20 a1=0.50 a2=0.90 dt=20 "+paratext+"";
	run("Anisotropic Diffusion 2D", op);
	run("Select All");
	run("Copy");
	close();
	selectImage(duporigID);
	run("Add Slice");
	run("Paste");
	drawString(paratext, 5, 30);
}
selectImage(refID);
close();
setBatchMode("exit and display");
