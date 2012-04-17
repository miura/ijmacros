path ="D:\\People\\Tina\\20110819b\\";
savepath = path + "out\\"; 
image = "segmented_f88_89.tif";
imp = IJ.openImage(path+image);
pivop1 ="piv1=128 piv2=64 piv3=0 what=[Accept this PIV and output] noise=0.20 threshold=5 c1=3 c2=1 ";
pivop2=path+image+".txt";
saveop = " save=" + pivop2;

op = pivop1 + " batch path=" + savepath;
op = pivop1 + " batch path=[" + path + "out]";
op = pivop1 + saveop + saveop + " batch";
op = pivop1 + saveop + " batch" + " path=[" + savepath+"]";
IJ.log(op); 
IJ.run(imp, "iterative PIV(Cross-correlation)...", op);
WindowManager.closeAllWindows();