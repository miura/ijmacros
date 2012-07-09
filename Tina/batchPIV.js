/* Batch processing script for PIV. 
The plugin-site: https://sites.google.com/site/qingzongtseng/piv

Change following variables 
	input files: path, savepath, imagestack
	PIV parameter: line 19

Kota Miura (miura@embl.de)
*/
//path ="D:\\People\\Tina\\20110813\\";
path = "Z:\\Tina\\";
//savepath = path + "out\\"; 
savepath = path + "outNoneSeg\\"; 
imagestack = "110608wt2.tif.proc.tif.noseg.tif";
imp = IJ.openImage(path+imagestack);
if (imp.getStackSize()<2) {
	IJ.error("spedified file is not a stack");
}
pivop1 ="piv1=128 piv2=64 piv3=0 what=[Accept this PIV and output] noise=0.20 threshold=5 c1=3 c2=1 ";
//IJ.run(imp, "iterative PIV(Cross-correlation)...", "piv1=128 piv2=64 piv3=0 what=[Accept this PIV and output] noise=0.20 threshold=5 c1=3 c2=1 save=[C:\\Documents and Settings\\Miura\\PIV_segmented_f284_285.txt]");
//"piv1=128 piv2=64 piv3=0 what=[Accept this PIV and output] noise=0.20 threshold=5 c1=3 c2=1"
importClass(Packages.ij.macro.Interpreter);
macro = new Interpreter(); 
macro.batchMode = true;
for (var i = 0; i < (imp.getStackSize() -1 ); i ++){
//for (var i = 0; i < (4 -1 ); i ++){
//for (var i = 285; i < 286; i ++){
	imppart = alias2frames(imp, i+1);		
	pivop2= savepath + imagestack + i + "_" + (i+1) + ".txt";
	saveop = " save=" + pivop2;
	op = pivop1 + saveop + " batch";
	IJ.log(op);
	IJ.log("=== Working on frame " + i + " and " + (i+1)); 
	try {
		//IJ.run(imppart, "iterative PIV(Cross-correlation)...", op);
		IJ.run(imppart, "iterative PIV(Cross-correlation)...", op);
	} catch(err){
		macro.batchMode = false;
		IJ.log("!Error with PIV");
		IJ.log(err.rhinoException.toString());
		IJ.log(err.javaException.toString());		
	}
	imppart.flush();
	imagewinKiller();
}
macro.batchMode = false;

function alias2frames(imp, i){
	stack = imp.getStack();
	tempstk = new ImageStack(imp.getWidth(), imp.getHeight());
	tempstk.addSlice(String(i), stack.getProcessor(i).clone());
	tempstk.addSlice(String(i+1), stack.getProcessor(i+1).clone());
	imp2 = new ImagePlus("temp", tempstk);	
	return imp2	
}

function imagewinKiller(){
	wins = WindowManager.getIDList();
	for (var i = 0; i < wins.length; i++)
		WindowManager.getImage(wins[i]).close();
}