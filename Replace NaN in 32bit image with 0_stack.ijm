
for (s = 0; s < nSlices; s++){
	setSlice(s+1);
	NaN20();
}
function NaN20(){
	newValue = 0.0;
	counter = 0;
	for (y = 0; y < getHeight(); y++){
	        for (x = 0; x < getWidth(); x++){
	                p = getPixel(x,y);
	                if (isNaN(p)) {
	                        setPixel(x, y, newValue);
	                        counter++;
	                }
	        }
	}
	print("" + counter + " pixels replaced"); 
}