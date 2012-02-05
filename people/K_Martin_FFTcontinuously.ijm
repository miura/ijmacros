/*
For continuous FFT of current image
written for realtime monitoring of FFT image of micromanager frame buffer

request from Martin Schorb (Briggs lab)

Kota Miura(cmci.embl.de) 20101214
*/
orgid = getImageID();
run("FFT");
fftid = getImageID();
setBatchMode(true);
while (!isKeyDown("space")){
	selectImage(orgid);
	run("FFT");
	fft2id = getImageID();
	run("Select All");
	run("Copy");
	close();
	selectImage(fftid);
	run("Paste");
	wait(100);
}
setBatchMode("exit and display");
