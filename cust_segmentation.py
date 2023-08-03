# -*- coding: utf-8 -*-
"""
Created on Wed May 24 02:49:56 2023

@author: amaru
"""

import pandas as pd
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

sales_data = pd.read_excel('D:/01. Portfolio Project One/sales_data_cleaned.xlsx')

repeated_customers_ids = sales_data.groupby('cust_id').filter(lambda x: len(x) >= 5)['cust_id'].unique()
repeated_customers = sales_data[sales_data['cust_id'].isin(repeated_customers_ids)]

avg_spending = repeated_customers[repeated_customers['cust_id'].isin(repeated_customers_ids)].groupby('cust_id')['total'].mean().reset_index()
avg_spending.columns = ['cust_id', 'avgSpending']

repeated_customers_new = repeated_customers.merge(avg_spending, on='cust_id', how='left')

repeated_customers_new['Customer Since'] = repeated_customers_new['Customer Since'].astype(str)

def get_last_four_or_keep_unknown(value):
    if value != 'Unknown':
        return value[-4:]
    else:
        return value

repeated_customers_new['Customer_Since_Year'] = repeated_customers_new['Customer Since'].apply(get_last_four_or_keep_unknown)


#Selecting the features relevant for segmentation
features = ['age', 'Gender', 'avgSpending', 'Customer_Since_Year']
features = repeated_customers_new[features]
features = pd.get_dummies(features)

#Kmeans Clustering
#Determine the optimal number of clusters using the elbow method
inertia = []
for num_clusters in range(1, 11):
    kmeans = KMeans(n_clusters=num_clusters, random_state=42)
    kmeans.fit(features)
    inertia.append(kmeans.inertia_)

# Plot the elbow curve to visualize the optimal number of clusters
import matplotlib.pyplot as plt
plt.plot(range(1, 11), inertia)
plt.xlabel('Number of Clusters')
plt.ylabel('Inertia')
plt.title('Elbow Curve')
plt.show()

# Choose the optimal number of clusters based on the elbow curve analysis
num_clusters = 3

# Perform K-means clustering with the chosen number of clusters
kmeans = KMeans(n_clusters=num_clusters, random_state=42)
kmeans.fit(features)

# Assign the cluster labels to the original dataset
repeated_customers_new['Cluster'] = kmeans.labels_

# View the resulting clusters
print(features.head())

repeated_customers_new.to_excel("D:/01. Portfolio Project One/kmeansClustering.xlsx", index=False)
















































