# -*- coding: utf-8 -*-
"""
Created on Thu Sep 22 00:37:47 2011

@author: -
"""
from mayavi import mlab

#obj = mlab.pipeline.open('/Users/miura/Dropbox/cell1.obj')
obj = mlab.pipeline.open('C:/dropbox/My Dropbox/cell1.obj')

cell = mlab.pipeline.surface(obj)
mlab.show()
