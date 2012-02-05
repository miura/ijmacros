importPackage(Packages.ij3d);
importPackage(Packages.javax.media.j3d);
importPackage(Packages.javax.vecmath);
//based on example code in 
// http://132.187.25.13/ij3d/?category=Documentation&page=devdoc/DisplayStack
imp = IJ.getImage();
StackConverter(imp).convertToGray8();
univ = new Image3DUniverse();
univ.show();

// Add the image as a volume rendering
c = univ.addVoltex(imp);

//following is from example in 
//http://132.187.25.13/ij3d/?category=Documentation&page=devdoc/ApplyTransformation

// Create a new Transform3D object
t3d = new Transform3D();
//set scaling
t3d.setScale(0.002);
//set rotation
//t3d.rotY(45 * Math.PI / 180);

// Apply the transformation to the Content. This concatenates
// the previous present transformation with the specified one
c.applyTransform(t3d);

//va = new ViewAdjuster(univ,ViewAdjuster.ADJUST_BOTH);
//va.apply();
univ.select(c);
univ.centerSelected(c);
//executer = new Executer(univ);
//executer.centerSelected(c);

// Display the Content in red
red = new Color3f(1, 0, 0);
c.setColor(red);
// Make it transparent
c.setTransparency(0.5);
