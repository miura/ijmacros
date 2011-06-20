/*
Extracting Time stamp info from Olympus file, and set the extracted time points to 
resuts table in ImageJ. 

Oriol +
Kota Miura (cmci.embl.de) 20101214
*/
prop = getImageInfo();
propA = split(prop, "\n");

// print(propA[4]);

counter =0;
for (i = 0; i < propA.length; i++){
	if (startsWith(propA[i], "timestamp")) {
		//print(propA[i]);
		counter ++;
	}
} 

print(""+counter+"points");
if (nSlices != counter) 
	exit("timepoints does not correspond to frame number");

timepointA = newArray(counter);

counter =0;
for (i = 0; i < propA.length; i++){
	if (startsWith(propA[i], "timestamp")) {
		lineA = split(propA[i], " ");
		// print(lineA[3]);  // timestamp
		// print(lineA[1]) // frame number
		timepointA[parseInt(lineA[1])] = parseInt(lineA[3]);
		counter++;
	}
} 
offset = timepointA[0];
for (i = 0; i<timepointA.length; i++) {
	timepointA[i] = timepointA[i] - offset;
	print(timepointA[i]/1000);
	setResult("Timepoint", i, timepointA[i]/1000);
}


