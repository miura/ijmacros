//color scale generator
// extracted from dot wuantification macro


macro "Create Scale" {
	bitdepth = bitDepth();
	print(bitdepth);
	rmin = 0;
	rmax = 255; // 8bit
	if (bitdepth == 16){
		rmax = 65535;
	} else if (bitdepth == 32) {
		getRawStatistics(nPixels, mean, min, max);
		rmin = min;
		rmax = max;		
	}
	visRatio(rmin, rmax, bitdepth, 100, 200);
}


function visRatio(rmin, rmax, bitdepth, winwidth, winheight){
	newImage("LUT scale", ""+bitdepth+"-bit black", winwidth, winheight, 1);
	stepsize = abs(rmax - rmin) / (winheight-1);
	addColorScale(rmin, rmax, 30, stepsize, bitdepth);
}

//add color scale in right side, 10pix width 256 height

function addColorScale(smin, smax, scalewidth, stepsize, bitdepth){
	sw = scalewidth; //scale width
//	hfactor = 3;
	topleftx = getWidth() -sw - 20;
	toplefty = 0;// getHeight()/2 - 256*hfactor/2;
	for (i=0; i<getHeight(); i++){
		for (j=0; j<sw; j++){
			setPixel(j + topleftx , i , smax - i * stepsize);
		}
	}
	smaxs = ""+smax;
	if ((smax <10000) && (lengthOf(smaxs)>4)) smaxs = substring(smaxs,0,4);
	smids = "" +  smax/2;
	smid = smax/2;
	if ((smid <10000) && (lengthOf(smids)>4)) smids =  substring(smids,0,4);
	smins = "" +  smin;
	if (lengthOf(smins)>4) smids =  substring(smins,0,4);

	//add values to scale
	setColor(smax);
	setFont("SansSerif", 10);
  	setJustification("right");
	drawString(smaxs , topleftx - 20, toplefty + 12);
	drawString(smids, topleftx - 20, toplefty + round(getHeight()/2));	 
	drawString(smins, topleftx - 20, toplefty + getHeight());	 
}