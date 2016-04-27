---
title: 统计学习方法 - EM算法
date: 2014-09-02 16:31:00
permalink: 1409646660000
tags: 机器学习
---

EM算法貌似是个比较重要的算法，推导了一遍公式，但感觉理解的还不够透彻，所以就不多写什么了。

“9.1.2 EM算法的导出”这一小节中的联合概率分布P(Y,Z|\theta)其实没必要展开，这样推导看起来能更简洁一点。

这里主要给出一段演示代码，主要用于高斯混合模型。用3组不同参数下的高斯分布随机函数产生观测数据（2维的），用EM算法通过这些数据反推出系统参数。图中黑点为观测数据，红绿蓝三色椭圆分别为计算所得的三个高斯分布生成函数的半波宽位置。

	'''
	EM algorithm for Gaussian misture model
	'''
	#head
	import numpy as np
	import matplotlib.pyplot as plt
	import random as rd
	import math
	########################
	def gaussian(y_j, mu_k, sigma_k):
		temp0 = ((y_j[0]-mu_k[0])/sigma_k[0])**2 + ((y_j[1]-mu_k[1])/sigma_k[1])**2
		return math.exp(-0.5*temp0) / (2*math.pi*sigma_k[0]*sigma_k[1])
	 
	def generate_gaussian(N, mu, sigma, alpha):
		K = len(alpha)
		n = []
		sum_N = 0
		for k in range(K-1):
			temp = int(N*alpha[k])
			n.append(temp)
			sum_N += temp
		n.append(N - sum_N)
		Y = []
		for k in range(K):
			Y = Y + [[rd.gauss(mu[k][0], sigma[k][0]), rd.gauss(mu[k][1], sigma[k][1])] for i in range(n[k])]
		return Y
	 
	def eclipse(mu, sigma):
		theta = [2*math.pi*i/999 for i in range(1000)]
		K = len(mu)
		for k in range(K):
			X = [sigma[k][0]*math.cos(i)+mu[k][0] for i in theta]
			Y = [sigma[k][1]*math.sin(i)+mu[k][1] for i in theta]
			if (k==0):
				clr = '-r'
			elif (k==1):
				clr = '-g'
			elif (k==2):
				clr = '-b'
			else:
				clr = '-k'
			plt.plot(X,Y,clr)
	##############
	#generate samples
	N = 10000
	mu = [[4.0,2.0], [8.0,15.0], [20.0,5.0]]
	sigma = [[2.0,3.0], [4.0,4.0], [3.0,1.0]]
	alpha = [0.2, 0.5, 0.3]
	Y = generate_gaussian(N, mu, sigma, alpha)
	x = [Y[i][0] for i in range(N)]
	y = [Y[i][1] for i in range(N)]
	###################
	K = len(alpha)
	N = len(Y)
	D = len(Y[0])
	#initial parameters
	mu = [[1.0,1.0], [2.0,4.0], [20.0,13.0]]
	sigma = [[2.0,1.0], [3.0,4.0], [2.0,3.0]]
	alpha = [0.4, 0.3, 0.3]
	#start
	for iteration in range(100):
		gamma=[]
		mu_old = mu[:]
		sigma_old = sigma[:]
		alpha_old = alpha[:]
	 
		for j in range(N):
			gamma.append([])
			for k in range(K):
				temp = sum([alpha[l]*gaussian(Y[j], mu[l], sigma[l]) for l in range(K)])
				gamma[j].append(alpha[k]*gaussian(Y[j], mu[k], sigma[k])/temp)
	 
		for k in range(K):
			for dim in range(D):
				temp1 = sum([gamma[j][k]*Y[j][dim]  for j in range(N)])
				sum_gamma = sum([gamma[j][k]  for j in range(N)])
				mu[k][dim] = temp1 / sum_gamma
				temp1 = sum([gamma[j][k]*((Y[j][dim]-mu[k][dim])**2)  for j in range(N)])
				sigma[k][dim] = math.sqrt(temp1 / sum_gamma)
			alpha[k] = sum_gamma / N
	 
		temp = 0.0
		temp += sum([(alpha[i]-alpha_old[i])**2 for i in range(len(alpha))])
		temp += sum([sum([(sigma[i][j]-sigma_old[i][j])**2 for j in range(len(sigma[i]))]) for i in range(len(sigma))])
		temp += sum([sum([(mu[i][j]-mu_old[i][j])**2 for j in range(len(mu[i]))]) for i in range(len(mu))])
		if (temp < 1e-20):
			break
	print iteration
	print mu
	print sigma
	print alpha
	plt.plot(x,y,',k')
	eclipse(mu, sigma)
	plt.show()
