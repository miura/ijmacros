f = open('Z:/likun/rapae1_cell1/rapa_e1CF_cell12D_0.snQP', 'r')
filestrA = f.read().split('\n')
frame = 0
segments = 0
frameA = []
xA = []
yA = []
for i in filestrA:
    #print i
    lineA = i.split('\t')
    if lineA[0].startswith('#'):
        if lineA[0].startswith('#Frame'):
            frame += 1
    else:
       if len(lineA)>1:
            #print lineA[1]
            frameA.append(int(frame))
            xA.append(float(lineA[1]))
            yA.append(float(lineA[2]))
       else:
          if len(lineA)==1: 
              segements = int(lineA[0])
              #print segments
import org.apache.commons.math.geometry.euclidean.twod.Vector2D as Vector2D
vecA = []
for idx, i in enumerate(xA):
    vec = Vector2D(xA[idx], yA[idx])
    vecA.append(vec)

f = open('Z:/likun/rapae1_cell1/rapa_e1CF_cell12D_0.stQP.csv', 'r')
filestrA = f.read().split('\n')
centA = []
centFrameA = []
for i in filestrA:
	if not i.startswith('#'):
		lineA = i.split(',')
		centFrameA.append(int(lineA[0]) + 1)
		centA.append(Vector2D(float(lineA[1]), float(lineA[2])))
		#print lineA[0]

radialA = []
for idi, i in enumerate(centFrameA):
	for idj, j in enumerate(frameA):
		if j == i:
			radialA.append(Vector2D(1, centA[idi].negate(), 1, vecA[idj]))
  
for i in radialA:
	print i.getNorm()

