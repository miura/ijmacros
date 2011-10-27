importClass(Packages.ij3d.image3d.IntImage3D);
imp=IJ.getImage();
ima=new IntImage3D(imp.getStack());
r=3;
ima2=ima.createLocalMaximaImage(r,r,r, true);
plus=new ImagePlus("localmaxima",ima2.getStack());
plus.show();