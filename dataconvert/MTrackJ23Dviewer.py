# Pavel @ arendt lab
# converting MTrackJ data to 3D track viewer
# 20120705-6
# Kota Miura (miura@embl.de) cmci.embl.de

import csv

#path to the MTrackJ track data file
sourcefilepath = '/Users/miura/Dropbox/ToDo/Pavel/data.txt'
# scales, micrometer per pixel
xyscale = 0.4131612
zscale = 1
#path to the output file: will be created if there is no file
outfilepath = '/Users/miura/Dropbox/ToDo/Pavel/dataconverted2.csv'

f = open(sourcefilepath, 'rb')
data = list(csv.reader(f, delimiter=' '))
f.close()

trackindex = []
tracknum = []
trackcolor = []
for idx, item in enumerate(data):
	if item[0] == 'Track':
		#IJ.log(str(idx))
		trackindex.append(idx)
		tracknum.append(item[1])
		trackcolor.append(item[2])
	if item[0] == 'End':
		trackindex.append(idx)

counter = 1

f = open(outfilepath, 'wb')
writer = csv.writer(f)
header = ['','TrackID','frame','Xpos','Ypos','Zpos','SXpos','SYpos','SZpos','ParticleID', 'Color']
writer.writerow(header)
for i in range(len(trackindex)-1):
#	IJ.log(str(trackindex[i]) + ", "+ str(trackindex[i+1]))
#	IJ.log('Track Number --> ' + str(tracknum[i]))
	for j in range(trackindex[i]+1, trackindex[i+1]):
		outrow = [counter, tracknum[i], data[j][5]]
		outrow += data[j][2:5] #pixelxy
		scaledx = float(data[j][2]) * xyscale
		scaledy = float(data[j][3]) * xyscale
		scaledz = float(data[j][4]) * zscale
		scaled = [scaledx, scaledy, scaledz]
		outrow += scaled		
		outrow += [data[j][1]] # particleID
		outrowstr = map(str, outrow)
#		IJ.log(str(data[j][1]) + ' x:' + str(data[j][2]))
		outrowstr += [trackcolor[i]]
		writer.writerow(outrowstr)
		IJ.log(', '.join(outrowstr))
		counter += 1
f.close()
