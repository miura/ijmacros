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

var optionsA = newArray("number", "smoothings", "keep", "a1", "a2","dt","edge");
var defalutvaluesA = newArray(20, 1, 20, 0.50, 0.90, 20, 5); //default values

diamessage = "Default Values:\n";
for (i = 0; i < optionsA.length; i++)
	diamessage = diamessage + optionsA[i] + "=" + defalutvaluesA[i]+ "\n";
	   
Dialog.create("Anisotoropic Diffusion2D Explorer");
Dialog.addMessage(diamessage); 
for (i = 0; i < optionsA.length; i++)
	Dialog.addNumber(optionsA[i], defalutvaluesA[i]);
Dialog.addChoice("Parameter", optionsA, "edge");
Dialog.addNumber("minimum", 1);
Dialog.addNumber("maximum", 2);
Dialog.addNumber("stepsize", 1);
Dialog.show();
for (i = 0; i < optionsA.length; i++)
	defalutvaluesA[i] = Dialog.getNumber();
exploreKey = Dialog.getChoice();
vmin = Dialog.getNumber();		//minimum of the parameter
vmax = Dialog.getNumber();		//maximum of the paramter
vstep = Dialog.getNumber();		//step size between vmin and vmax

/*
exploreKey = "edge"; 	//this key could be changed to vary other parameters
vmin = 1;		//minimum of the parameter
vmax = 5;		//maximum of the paramter
vstep = 2;		//step size between vmin and vmax
*/
runFilter(optionsA, defalutvaluesA, exploreKey, vmin, vmax, vstep);

function runFilter(kA, vA, varKey, vmin, vmax, vstep){
	run("Colors...", "foreground=white background=black selection=yellow");
	originalID = getImageID();
	run("Duplicate...", "title=testFiltering");
	duporigID = getImageID();
	run("Select All");
	run("Copy");
	setBatchMode(true);
	for (i = vmin; i < vmax; i+=vstep){
		selectImage(duporigID);
		if (i == vmin){
			run("Duplicate...", "title=orginal");
			refID = getImageID();
		}
		selectImage(refID);
		paratext = varKey + "=" + i;
		//op = "number=20 smoothings=1 keep=20 a1=0.50 a2=0.90 dt=20 "+paratext+"";
		op = ReturnOptionString(kA, vA, varKey, i);
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
}
function ReturnOptionString(keyA, valA, variableKey, variableVal){

	for (i = 0; i < keyA.length; i++)
		List.set(keyA[i], valA[i]);
	optlist = List.getList();
	//print(optlist);
	opt = "";
	for (i = 0; i < keyA.length; i++){
		if (keyA[i] != variableKey)
			opt = opt + keyA[i] + "=" + List.get(keyA[i])+ " ";
		else
			opt = opt + variableKey + "=" + variableVal+ " ";
	}
	return opt;
}
