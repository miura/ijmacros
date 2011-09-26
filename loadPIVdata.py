from matplotlib import mlab

filename = '/Users/miura/Dropbox/data/segmented.tif91_92.txt'
x, y, ux1, uy1, mag1,	ang1= mlab.load(filename, usecols=[0,1,2,3,4,5], unpack=True)



