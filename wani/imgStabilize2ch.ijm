orgTitle = getTitle();
run("Split Channels");
c1title = "C1-"+orgTitle;
c2title = "C2-"+orgTitle;
selectImage(c2title);

op = "transformation=Affine "+
	"maximum_pyramid_levels=1 "+
	"template_update_coefficient=0.90 "+
	"maximum_iterations=200 "+
	"error_tolerance=0.0000001 "+
	"log_transformation_coefficients";

run("Image Stabilizer", op);
selectImage(c1title);
run("Image Stabilizer Log Applier", " ");
selectWindow("C2-20120904_s04_g1el-1.log");
run("Close");



