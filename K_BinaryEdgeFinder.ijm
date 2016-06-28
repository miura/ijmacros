// line ROI on binary image, find the closest edge of the binary image. 

macro "Edge Finder Pixel by Pixel"{
	getLine(x1, y1, x2, y2, lineWidth);
	print("Deviation="+RadialDeviation(x1, y1, x2, y2));
}

function RadialDeviation(rimposx, rimposy, centx, centy, dapiedgeposxA, dapiedgeposyA, iter){
	getDimensions(width, height, channels, slices, frames);
	if ((centx) > (width - centx)) radx =  (width-centx);
	else radx = centx;

	if ((centy) > (height - centy)) rady = (height - centy);
	else rady = centy;

	if (radx > rady) roiradius = rady -1;
	else roiradius = radx -1;

	rimdist = Return2Ddist(rimposx, rimposy, centx, centy);

	currentpixel = getPixel(rimposx, rimposy);
	print("rim Dapi int: "+currentpixel );
	
	edgex =1000000;
	edgey =1000000;
	radincrement =0;
	direction = 0;
	counter = 0;
	do {
		radincrement +=1;
		inwardx = round( (rimposx - centx) / rimdist * (rimdist - radincrement) + centx);
		inwardy = round( (rimposy - centy) / rimdist * (rimdist - radincrement) + centy);

		outwardx = round( (rimposx - centx) / rimdist * (rimdist + radincrement) + centx);
		outwardy = round( (rimposy - centy) / rimdist * (rimdist + radincrement) + centy);
		//print("in("+inwardx +","+inwardy+")");
		//print("out("+outwardx +","+outwardy+")");
		if (getPixel(inwardx,inwardy) !=currentpixel ) {
			edgex = inwardx; 
			edgey = inwardy; 
			direction = -1;
		}
		else {
			if (getPixel(outwardx,outwardy) !=currentpixel ) {
				edgex = outwardx; 
				edgey = outwardy; 
				direction = 1;
			}
		}
			
	} while ((edgex==1000000) || (counter>2000)) ;
	print("DAPI edge:=("+edgex+", "+edgey+")");
	dapiedgeposxA[iter] =edgex;
	dapiedgeposyA[iter] =edgey;
	
	deviation = Return2Ddist(rimposx , rimposy , edgex, edgey) * direction ;
	return deviation;
}



//**********

function Return2Ddist(x1, y1, x2, y2){
	return sqrt(pow((x1 -x2), 2) + pow((y1 -y2), 2));
}



function calcDeviationradially(rimposxA, rimposyA, nucID,centx, centy, dapiedgeposxA, dapiedgeposyA, minimdist2A) {
	selectImage(nucID);
	for(i=0; i<rimposxA.length; i++) {
		print("deg"+i*10);
		minimdist2A[i] = RadialDeviation(rimposxA[i], rimposyA[i], centx, centy, dapiedgeposxA, dapiedgeposyA, iter);
	}
}
		
