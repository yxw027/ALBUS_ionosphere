#!/usr/bin/env python

import os
import sys
import numpy
import math 
from copy import deepcopy
from pylab import *

from string import split, strip

def getdata( filename ):
        text = open(filename, 'r').readlines()
        L = len(text)
        i = 0
        # skip over all stuff before actual data
        while(text[i][0:13] != 'seq  rel_time'):
           i = i+1

        elev = []
        rel_time = []
        start = i+1
        # get actual data
        for i in range( start,len(text)):
          try:
            info = split(strip(text[i]))
            if int(info[2]) == 0:
              latest = float(info[3]) / 3600
              rel_time.append(float(info[3]) / 3600)
              elev.append(numpy.degrees(float(info[5])))
          except:
            pass
        elev_arr = numpy.array(elev)
        return rel_time, elev_arr, latest

def main( argv ):
  print 'processing ALBUS file ', argv[1]
  x_data, y_data, latest  = getdata(argv[1])
  xlim(0,latest)
# xlim(0,25)
  plot(x_data, y_data,'r')
  xlabel('relative time (hours)')
  ylabel('Elevation (degrees)')
  title_string = 'Elevation as a function of time'
  plot_file =  argv[1] + '_elev_plot'
  title(title_string)
  grid(True)

# remove and "." in this string
  pos = plot_file.find('.')
  if pos > -1:
    plot_file = plot_file.replace('.','_')
  savefig(plot_file)
  show()


#=============================
# argv[1]  incoming ALBUS results file 
if __name__ == "__main__":
  main(sys.argv)
