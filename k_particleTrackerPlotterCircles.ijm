/* plots tracks detected by Particle Tracker in the corresponding image Stack.
 * Track results should be transferred to the Results window
 * by "All Trajectories to Table" button before executing this macro. 
 * 
 * Convert the stack to RGB before execution as well. 
 * 
 * Kota Miura (miura@embl.de) 20111027
 */

//plotting color
setForegroundColor(255, 153, 0); 

for (i = 0; i < nResults; i++) {
	y = getResult("x", i);
	x = getResult("y", i);
	slice = getResult("frame", i);
	setSlice(slice+1);
	diameter = 8;
	tx = x - diameter/2;
	ty = y - diameter/2;
	makeOval(tx, ty, diameter, diameter);
	run("Draw", "slice");
}

setForegroundColor(255, 255, 255);

