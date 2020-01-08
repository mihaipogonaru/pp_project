import numpy as np
import numpy.ma as ma

import matplotlib.pyplot as plt
import matplotlib.colors as colors

x = []
y = []
max_x = 0
with open("initial_points") as f:
    line = f.readline().strip()
    while line:
        x_elem = line.split(" ")[0]
        y_elem = line.split(" ")[1]
        x.append(int(x_elem))
        y.append(int(y_elem))
        line = f.readline().strip()


line_x = []
line_y = []
with open("final_points") as f:
    line = f.readline().strip()
    while line:
        x_elem = line.split(" ")[0]
        y_elem = line.split(" ")[1]
        line_x.append(int(x_elem))
        line_y.append(int(y_elem))
        line = f.readline().strip()

line_x.append(line_x[0])
line_y.append(line_y[0])
plt.plot(x, y, 'ro')
plt.plot(line_x, line_y, 'ro-')
plt.axis([0, 200, 0, 200])
plt.show()


