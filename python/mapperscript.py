'''
    Python Mapper script
    Generated by the Python Mapper GUI
'''

import mapper
import numpy as np
import matplotlib.pyplot as plt
import matplotlib
from utilitiesData import *
from sklearn import decomposition
from matplotlib.patches import Polygon
from matplotlib.collections import PatchCollection



'''
    Step 1: Input
'''
X, names, column = loadData('data/data_players_7stats.csv')

# Preprocessing
point_labels = None
mask = None
Gauss_density = mapper.filters.Gauss_density
kNN_distance  = mapper.filters.kNN_distance
crop = mapper.crop
# Custom preprocessing code
# TODO: CUSTOM CODE
data = X
# data = np.delete(X, 4, axis=1)
print(data[0, :])
data = X / np.std(X, axis = 0)
# End custom preprocessing code
data, point_labels = mapper.mask_data(data, mask, point_labels)
'''
    Step 2: Metric
'''
intrinsic_metric = False
if intrinsic_metric:
    is_vector_data = data.ndim != 1
    if is_vector_data:
        metric = Euclidean
        if metric != 'Euclidean':
            raise ValueError('Not implemented')
    data = mapper.metric.intrinsic_metric(data, k=1, eps=1.0)

is_vector_data = data.ndim != 1

'''
    Step 3: Filter function
'''

if is_vector_data:
    metricpar = {'metric': 'euclidean'}
    f = mapper.filters.zero_filter(data,
        metricpar=metricpar)
else:
    f = mapper.filters.zero_filter(data)

# Filter transformation

mask = None
crop = mapper.crop
# Custom filter transformation
# TODO: CUSTOM CODE

pca = decomposition.PCA(2)
pca.fit(data)
filtration_axis = pca.components_

f = np.dot(data, np.transpose(filtration_axis))

# End custom filter transformation

'''
    Step 4: Mapper parameters
'''


cover = mapper.cover.cube_cover_primitive(intervals=15, overlap=50.0)
# cover = mapper.cover.balanced_cover_1d(intervals=20, overlap=50.0)
cluster = mapper.single_linkage()
if not is_vector_data:
    metricpar = {}

mapper_output = mapper.mapper(data, f,
    cover=cover,
    cluster=cluster,
    point_labels=point_labels,
    cutoff=None,
    metricpar=metricpar, verbose = True)

cutoff = mapper.cutoff.first_gap(gap=0.1)
mapper_output.cutoff(cutoff, f, cover=cover, simple=False)



# TODO Jusque la ca marche
# CUSTOM GRAPH VISUALIZATION

# mapper_output.simplices[d][t1, ..., td] -> = 1 iff exists simplicial complex of order d between t1, ..., td
# mapper_output.nodes == node((index, ), array([num]), value) -> player number 'num' is in node 'index', however wtf is value ?

fig, ax = plt.subplots()
number_nodes = len(mapper_output.nodes)
nodes_centroid = np.zeros([number_nodes, 2])
points_per_node = np.zeros(number_nodes)

# computing number of nodes
number = 0
for i in range(0, number_nodes):
    points_per_node[i] = len(mapper_output.nodes[i].points)
    nodes_centroid[i] = np.mean(f[mapper_output.nodes[i].points], axis = 0)

    # mapper_output.nodes[i].level
    # mapper_output.nodes[i].attribute
    # mapper_output.nodes[i].points

# ploting 0-dim simplices
ax.plot(nodes_centroid[:, 0], nodes_centroid[:, 1], 'ro')
# for i in range(0, number_nodes):
#     plt.annotate(str(int(points_per_node[i])), xy = (nodes_centroid[i, 0], nodes_centroid[i, 1]))
ax.plot(f[:, 0], f[:, 1], 'g.')

# ploting 1-dim simplices
vertices = []
for (n1, n2) in mapper_output.simplices[1]:
    if n1 < n2:
        vertices.append(np.array([nodes_centroid[n1, :], nodes_centroid[n2, :]]))
        ax.plot([nodes_centroid[n1, 0], nodes_centroid[n2, 0]], [nodes_centroid[n1, 1], nodes_centroid[n2, 1]], 'b')


# ploting 2-dim simplices
patches = []
for (n1, n2, n3) in mapper_output.simplices[2]:
    if n1 < n2 & n2 < n3:
        polygon = Polygon(nodes_centroid[[n1, n2, n3], :])
        patches.append(polygon)

p = PatchCollection(patches, cmap=matplotlib.cm.jet, alpha=0.4)
ax.add_collection(p)

plt.show()



# mapper_output.draw_scale_graph()
# plt.savefig('scale_graph.png')
# '''
#     Step 5: Display parameters
# '''
# # Node coloring
#
# nodes = mapper_output.nodes
# node_color = None
# point_color = None
# name = 'custom scheme'
# # Custom node coloring
# # TODO: CUSTOM CODE
# coloring_axis = pca.components_[1]
# point_color = np.dot(data, coloring_axis)
# # End custom node coloring
# node_color = mapper_output.postprocess_node_color(node_color, point_color, point_labels)
# minsizes = []
# mapper_output.draw_2D(minsizes=minsizes,
#     node_color=node_color,
#     node_color_scheme=name)
# plt.savefig('mapper_output.png')
# plt.show()