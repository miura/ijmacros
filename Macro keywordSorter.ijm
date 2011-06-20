// for sorting macro function keywords 
// to be used for creating syntax highlighter file for vim. 
origs = "pow getResultsCount changeValues wait getResult setLocation setColor matches doWand substring setVoxelSize setOption getTitle setThreshold List.setList List.clear setJustification getArgument eval log isActive nImages floor toLowerCase Dialog.addString isNaN split getDimensions getString Stack.setActiveChannels String.paste File.name Fit.nEquations List.size debug run bitDepth invert selectionName getVersion makeLine getLine getSelectionBounds List.getValue Stack.setChannel File.directory write setLut getPixelSize Stack.setSlice sqrt Stack.getPosition Stack.setFrameRate String.append replace setKeyDown imageCalculator getTime charCodeAt sin Fit.rSquared Overlay.moveTo setMinAndMax Overlay.show cos round showProgress Overlay.removeSelection putPixel close getResultLabel toUpperCase Fit.getEquation newMenu calibrate makePoint selectImage Stack.isHyperstack setRGBWeights getDateAndTime Dialog.addCheckboxGroup Dialog.getString Dialog.addHelp showText autoUpdate makeSelection screenWidth minOf getZoom exec getFontList parseFloat getValue parseInt dump asin newArray String.resetBuffer File.openDialog Dialog.show atan2 getHeight d2s waitForUser Overlay.lineTo floodFill Fit.doFit getLocationAndSize startsWith selectionContains getSliceNumber lineTo newImage Dialog.addCheckbox setBackgroundColor drawString toHex File.openUrlAsString Fit.showDialog getDirectory Array.copy screenHeight getStringWidth File.length getBoundingRect String.buffer setPasteMode getNumber showMessageWithCancel makeOval showMessage IJ.currentMemory Dialog.getCheckbox fillRect indexOf File.separator File.isDirectory open getFileList Stack.setZUnit abs Ext getThreshold nSlices resetMinAndMax File.append reset updateResults doCommand setBatchMode File.exists setFont random Overlay.drawString Stack.setPosition lastIndexOf makeText restoreSettings drawOval Stack.getDisplayMode exit restorePreviousTool makePolygon Dialog.addNumber roiManager setTool getRawStatistics getList setForegroundColor File.rename makeRectangle IJ.deleteRows setAutoThreshold tan List.getList File.open setMetadata Dialog.addChoice getVoxelSize Stack.getFrameRate toolID IJ.freeMemory Array.getStatistics IJ.redirectErrorMessages setSelectionName fromCharCode File.openAsString Fit.plot Array.invert snapshot getPixel Stack.setDimensions Overlay.size isOpen Array.sort selectionType getLut Overlay.remove Overlay.drawLine getStatistics getMetadata setSelectionLocation File.nameWithoutExtension atan save File.lastModified getBoolean File.delete rename String.copy beep Stack.getDimensions Fit.logResults getSelectionCoordinates getMinAndMax Fit.nParams getWidth Stack.getStatistics maxOf toBinary getImageInfo drawRect File.openAsRawString requires setLineWidth exp File.makeDirectory File.dateLastModified getCursorLoc Stack.setTUnit selectWindow Array.fill getProfile setPixel toString String.copyResults showStatus Stack.swap saveSettings Dialog.addMessage setSlice call File.getName Overlay.drawEllipse nResults IJ.maxMemory getInfo File.getParent lengthOf saveAs Dialog.getChoice setResult updateDisplay isKeyDown drawLine acos Overlay.drawRect List.get moveTo is Overlay.add setZCoordinate fillOval IJ.getToolName fill setupUndo Stack.setDisplayMode print getHistogram runMacro getImageID List.set Stack.setFrame List.setMeasurements File.close resetThreshold endsWith List.setCommands Plot\.create Plot\.setLimits Plot\.setColor Plot\.add Plot\.addText Plot\.show Plot\.setLineWidth Plot\.setLineWidth Plot\.setJustification Dialog.create  File.separator File.openAsString
";
sA = split(origs, " ");
nodot = "";
withdot = "";
for(i = 0; i < sA.length; i++){
	cs = indexOf(sA[i],".");
	if (( cs > 0 ) &&  (cs < (sA.length-1))) {
		withdot + =sA[i]+" ";
	} else {
		nodot + =sA[i]+" ";
	}
}
	print(nodot);
	print("");
	//print(withdot);
	//print("");

origs = withdot;
wdA = newArray("Array", "File", "Fit", "IJ.", "List", "Overlay", "Stack", "String");
for (j = 0; j<wdA.length; j++) {
	sA = split(origs, " ");
	withkey = "";
	nokey = "";
	for(i = 0; i < sA.length; i++){
		if (startsWith(sA[i],wdA[j])) {
			withkey + =sA[i]+" ";
		} else {
			nokey + =sA[i]+" ";
		}
	}
	print(withkey);
	print("");
	origs = nokey;
  }
/*
origs = nokey;
sA = split(origs, " ");
withkey = "";
nokey = "";
for(i = 0; i < sA.length; i++){
	if (startsWith(sA[i],"Array")) {
		withkey + =sA[i]+" ";
	} else {
		nokey + =sA[i]+" ";
	}

  }
	print(withkey);
	print("");

origs = nokey;
sA = split(origs, " ");
withkey = "";
nokey = "";
for(i = 0; i < sA.length; i++){
	if (startsWith(sA[i],"Fit")) {
		withkey + =sA[i]+" ";
	} else {
		nokey + =sA[i]+" ";
	}

  }
	print(withkey);
	print("");

origs = nokey;
sA = split(origs, " ");
withkey = "";
nokey = "";
for(i = 0; i < sA.length; i++){
	if (startsWith(sA[i],"Stack")) {
		withkey + =sA[i]+" ";
	} else {
		nokey + =sA[i]+" ";
	}

  }
	print(withkey);
	print("");

origs = nokey;
sA = split(origs, " ");
withkey = "";
nokey = "";
for(i = 0; i < sA.length; i++){
	if (startsWith(sA[i],"Overlay")) {
		withkey + =sA[i]+" ";
	} else {
		nokey + =sA[i]+" ";
	}

  }
	print(withkey);
	print("");

*/
