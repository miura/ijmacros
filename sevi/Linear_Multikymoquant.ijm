/*
Sevi's kymoquant extension, 
analyze kymograph along specified line ROI. 
201201025, sent from Sevi via email. 

*/
//------------------------------------------------------------------------------------------------------------
macro "Multiple ROIs from Line Selection"{
        if (selectionType()==0) exit("need a line or segmented-line ROI");
        getSelectionCoordinates(xc, yc);
		boxsize = getNumber("unit area size in Pixels?", 60);
		frame_interval=getNumber("calculate for every ... frame", 1);
		
		//total number of boxes to be calculated (based on time axis)
		total_y_length=yc[yc.length-1]-yc[0];
		number_of_boxes=floor(total_y_length/frame_interval)+1;
		
		//get slopes and xy coordinates along roi
		slope_array=newArray(number_of_boxes);
		slope_array[0]=0;
		newx_array=newArray(number_of_boxes);
		newx_array[0]=xc[0];
		newy_array=newArray(number_of_boxes);
		newy_array[0]=yc[0];
		
		newx=xc[0];
		newy=yc[0];

		for(i = 1; i < number_of_boxes; i++){
			newy=newy+frame_interval;
			closest=-1;
			for(j=0; j<yc.length-1;j++){
				if(newy>=yc[j]){
					closest=j;
				}
    	    }
			slope_array[i]=(yc[closest+1]-yc[closest])/(xc[closest+1]-xc[closest]);
			newy_array[i]=newy;
			newx=newx+round(frame_interval/slope_array[i]);
			newx_array[i]=newx;
		}


/////--

		getDimensions(imgw, imgh, chs, imgslices, imgframes);
		
        bigimgID = getImageID();
        sampledim = boxsize;
        setFont("SansSerif", 10);
        setJustification("center");
        newImage("velocity", "8-bit Black", imgw, imgh, 1);
        run("Add...", "value=100");
        velimgID = getImageID();

        IJ.log("x coordinate,y coordinate,velocity(pixel/frame)");

        for(boxnum=0;boxnum<number_of_boxes;boxnum++){
	        selectImage(bigimgID);
	
	        makeRectangle(newx_array[boxnum]-(sampledim/2) ,
	        	newy_array[boxnum]-(sampledim/2) , 
	        	sampledim , 
	        	sampledim);
	        run("Copy");
	        setBatchMode(true);
	        newImage("temppart", "8-bit Black", sampledim , sampledim, 1);
	        duporgID = getImageID();
	        run("Paste");
	        origID = getImageID();
	        roughestimate = kymographVelMeasureReturnAngle(origID, 10, 180, 180, 0, 1);
	        rotation = kymographVelMeasureReturnAngle(origID, 0.2, roughestimate , 50, 0, 2);
	        selectImage(duporgID);
	        close();
	        setBatchMode("exit and display");
	        netrotation = rotation ;
	        if (rotation>180) netrotation = rotation -180;
	        if ((netrotation !=90) && (netrotation !=270)) {
	                tangent = tan(netrotation/180*3.1415);
	        } else {
	                tangent = NaN;          // vertical,
	        }
	        velocity = tangent; // pixels / frame
	        selectImage(velimgID);
	        strop = ""+d2s(velocity, 3);
	        drawString(strop , newx_array[boxnum], newy_array[boxnum]);
	        print_array=newArray(3);
	        print_array[0]=newx_array[boxnum];
	        print_array[1]=newy_array[boxnum];
	        print_array[2]=velocity;
	        Array.print(print_array);

	    }
}
//------------------------------------------------------------------------------------------------------