# import topslam
import os
import sys
import json
import pandas as pd
import topslam
from topslam.optimization import run_methods, create_model, optimize_model
from topslam import ManifoldCorrectionTree

temp_folder = sys.argv[1]

# Load params
p = json.load(open(temp_folder + "/params.json", "r"))

Y = pd.read_table(temp_folder + "/counts.tsv", index_col=0)

from sklearn.manifold import TSNE, LocallyLinearEmbedding, SpectralEmbedding, Isomap
from sklearn.decomposition import FastICA, PCA

methods = {'t-SNE':TSNE(n_components=p["n_components"]),
           'PCA':PCA(n_components=p["n_components"]),
           'Spectral': SpectralEmbedding(n_components=p["n_components"], n_neighbors=p["n_neighbors"]),
           'Isomap': Isomap(n_components=p["n_components"], n_neighbors=p["n_neighbors"]),
           'ICA': FastICA(n_components=p["n_components"])
           }
methods = {method_name:method for method_name, method in methods.iteritems() if method_name in p["dimreds"]}

print("Dimensionality reduction")

X_init, dims = run_methods(Y, methods)

print("Modelling")
m = create_model(Y, X_init, linear_dims=p["linear_dims"])
m.optimize(messages=1, max_iters=p["max_iters"])

print("Manifold correction")

m_topslam = ManifoldCorrectionTree(m)
pt_topslam = m_topslam.get_pseudo_time(start=p["start_cell_id"], estimate_direction=True)

# also export landscape for plotting later

print("Calculating landscape")
landscape = topslam.landscape.waddington_landscape(m, resolution=100, xmargin=(0.5, 0.5), ymargin=(0.5, 0.5))

print("Saving")
pd.DataFrame(landscape[0], columns=["x", "y"]).to_csv(temp_folder + "/wad_grid.csv", index=False)
pd.DataFrame(landscape[1], columns=["energy"]).to_csv(temp_folder + "/wad_energy.csv", index=False)
pd.DataFrame(landscape[2], columns=["Comp" + str(i+1) for i in range(landscape[2].shape[1])]).to_csv(temp_folder + "/space.csv", index=False)
pd.DataFrame(pt_topslam, columns=["time"]).to_csv(temp_folder + "/pseudotime.csv", index=False)
