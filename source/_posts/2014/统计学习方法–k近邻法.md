---
title: 统计学习方法 – k近邻法
date: 2014-08-28 11:18:00
permalink: 1409195880000
tags: 机器学习
---

k近邻法(K-nearest neighbor, KNN)是一个比较简单的算法，概括来说就2步：

1. 计算输入点到训练数据集中所有数据点的距离，找出k个离输入点最近的训练点。
2. 这k个点多数属于哪个类别，这个输入点就是该类别。

如果暴力求解这个问题，就是以下步骤：

1. 遍历整个训练集，计算所有训练点到输入点距离。
2. 按距离远近对这些训练点排序。
3. 取前k个训练点，对这k个点统计各个类别所含数据点的数目，该输入点就属于所含数据点最多的类别。

暴力解法的缺点在于需要遍历计算输入点到所有数据点的距离，并进行排序。书中给出了一种数据结构来优化这一算法：kd树，这个优化算法最复杂的地方就是构造kd树和搜索kd树。

以下给出一段暴力算法的程序，使用红绿蓝三色X标记了三个类别的训练点，用三角形标记了输入点，用圆形标记输入点的k个近邻点，输入点的颜色取决于k个近邻点最多的那种颜色。程序主要以实现算法为主，写得比较冗杂：

	import numpy as np
	import matplotlib.pyplot as plt
	import random as rd
	import math
	###############
	def generate_T(N):
    	M = 3
    	N_m = []
    	T = []
    	for i in range(M-1):
        	N_m.append(int(N/M))
    	N_m.append(N - (M-1)*int(N/M))
    	for m in range(M):
        	for i in range(N_m[m]):
            	T.append([[rd.random()*(m+1),rd.random()*(m+1)], m])
    	return T
 
	def plot_result(k, z, T, Lp):
    	N = len(T)
    	for i in range(N):
        	if (T[i][1] == 0):
            	plt.plot(T[i][0][0],T[i][0][1],'xr')
        	elif (T[i][1] == 1):
            	plt.plot(T[i][0][0],T[i][0][1],'xg')
        	elif (T[i][1] == 2):
            	plt.plot(T[i][0][0],T[i][0][1],'xb')
        	else:
            	pass
    	if (z[1] == 0):
        	plt.plot(z[0][0],z[0][1],'^r')
    	elif (z[1] == 1):
        	plt.plot(z[0][0],z[0][1],'^g')
    	elif (z[1] == 2):
        	plt.plot(z[0][0],z[0][1],'^b')
    	else:
        	pass
    	for i in range(k):
        	if (T[Lp[i][1]][1] == 0):
            	plt.plot(T[Lp[i][1]][0][0], T[Lp[i][1]][0][1], 'or')
        	elif (T[Lp[i][1]][1] == 1):
            	plt.plot(T[Lp[i][1]][0][0], T[Lp[i][1]][0][1], 'og')
        	elif (T[Lp[i][1]][1] == 2):
            	plt.plot(T[Lp[i][1]][0][0], T[Lp[i][1]][0][1], 'ob')
        	else:
            	pass
    	plt.xlabel('$x^{(1)}$')
    	plt.ylabel('$x^{(2)}$')
    	plt.show()
 
	def cal_distance(p, x, x_T):
    	dim = len(x)
    	return pow(sum([pow(abs(x[l]-x_T[l]),p) for l in range(dim)]), 1.0/p)
 
	def cal_Lp(p, x, T):
    	N = len(T)
    	Lp = []
    	for i in range(N):
        	d = cal_distance(p, x, T[i][0])
        	Lp.append((d, i))
    	Lp.sort()
    	return Lp
 
	def classify(k, x, Lp, T):
    	count = [0, 0, 0]
    	for i in range(k):
        	if (T[Lp[i][1]][1] == 0):
            	count[0] += 1
        	elif (T[Lp[i][1]][1] == 1):
            	count[1] += 1
        	elif (T[Lp[i][1]][1] == 2):
            	count[2] += 1
        	else:
            	pass
    	count_list = [(count[0], 0),(count[1], 1),(count[2], 2)]
    	count_list.sort()
    	z = [x,count_list[2][1]]
    	return z
	###############
	N = 100 #size of test set
	p = 2
	k = 10
	x = [1.1, 1.1]
	T = generate_T(N)
	Lp = cal_Lp(p, x, T)
	z = classify(k, x, Lp, T)
	plot_result(k, z, T, Lp)