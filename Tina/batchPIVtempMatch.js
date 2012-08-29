/* Batch processing script for PIV, using template matching. 
The plugin-site: https://sites.google.com/site/qingzongtseng/piv

 ======== Change following variables  ======== 
	input files: path, savepath, imagestack line 17-19
	PIV parameter: line 21-28
 ========  ========  ========  ========  ======== 	
Kota Miura (miura@embl.de)
2011 for Tina
20120829 for Matteo: updated version, using template matching, not cross-correlation. 
*/

importClass(Packages.java.io.File);
importClass(Packages.ij.macro.Interpreter);

// ======== File IO  ======== 
path = "/Volumes/D/Matteo/";
savepath = path + "vecdata/"; 
imagestack = "name_Concatenated_Stacks.tif";
//  ======== parameters for template matching ======== 
piv1 = 128;
piv2 = 64;
piv3 = 48;
cor = 0.60;
noise = 0.20;
threshold = 5;
c1 = 3;
c2 = 1;
//  ========  ======== 
sw1 = piv1 * 2;
sw2 = piv2 * 2;
sw3 = sw2;  

imp = IJ.openImage(path+imagestack);
if (imp.getStackSize()<2) {
	IJ.error("spedified file is not a stack");
}
outdir = File(savepath);
if (!outdir.exists()) {
	outdir.mkdir();
}
//pivop1 ="piv1=128 piv2=64 piv3=0 what=[Accept this PIV and output] noise=0.20 threshold=5 c1=3 c2=1 ";
// for crosscorrelation
//pivop1 = "piv1="+piv1+" piv2="+piv2+" piv3="+piv3+" what=[Accept this PIV and output] noise="+noise+" threshold="+threshold+" c1="+c1+" c2="+c2+" ";
// for temp matching
pivop1 = 	"piv1=" + piv1 + 
		" sw1=" + sw1 +
		" piv2=" + piv2 + 
		" sw2=" + sw2 +
		" piv3=" + piv3 + 
		" sw3=" + sw3 + 
		" correlation=" + cor + 
		" what=[Accept this PIV and output] " + 
		"noise=" + noise + 
		" threshold=" + threshold + 
		" c1=" + c1 + 
		" c2=" + c2 + " ";

IJ.log(pivop1);
macro = new Interpreter(); 
macro.batchMode = true;
for (var i = 0; i < (imp.getStackSize() -1 ); i ++){
	imppart = alias2frames(imp, i+1);		
	pivop2= savepath + imagestack + i + "_" + (i+1) + ".txt";
	saveop = " save=" + pivop2;
	op = pivop1 + saveop + " batch";
	IJ.log(op);
	IJ.log("=== Working on frame " + i + " and " + (i+1)); 
	try {
		//IJ.run(imppart, "iterative PIV(Cross-correlation)...", op);
		IJ.run(imppart, "iterative PIV(Basic)...", op);
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

// extracts a two-frame stack
function alias2frames(imp, i){
	stack = imp.getStack();
	tempstk = new ImageStack(imp.getWidth(), imp.getHeight());
	tempstk.addSlice(String(i), stack.getProcessor(i).clone());
	tempstk.addSlice(String(i+1), stack.getProcessor(i+1).clone());
	imp2 = new ImagePlus("temp", tempstk);	
	return imp2	
}

//closes all opened windows. 
function imagewinKiller(){
	wins = WindowManager.getIDList();
	for (var i = 0; i < wins.length; i++)
		WindowManager.getImage(wins[i]).close();
}