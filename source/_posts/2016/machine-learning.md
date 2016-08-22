---
title: Machine Learning 课程小结
date: 2016-08-22 10:08:45
permalink: 1471831725000
tags: 机器学习
---

最近在 Coursera 上完成了第一门课：Andrew Ng 的 Machine Learning，拿到了第一个 Certification。体验挺好的，这篇文章把各个知识点大体梳理一下，备忘。

## Introduction

Machine Learning 这个概念有两种定义：

1. The field of study that gives computers the ability to learn without being explicitly programmed.
2. A computer program is said to learn from experience E with respect to some class of tasks T and performance measure P, if its performance at tasks in T, as measured by P, improves with experience E.

它大体可以分为两类：

1. supervised learning
2. unsupervised learning

前者的学习需要以往数据给出一定的「指导」，而后者可以自发地从数据中摸索出一定的「规律」。
<!-- more -->
### Supervised learning

Supervised learning 的问题又可以分为两类问题：regression 和 classification。前者预测的值一般是连续的，例如根据以往的运营情况预测未来的盈利；后者预测的值是离散的，例如预测是否得癌症。

这一类问题在这门课中讲了以下四种方法：

1. Linear Regression
2. Logistic Regression
3. Neural Networks
4. Support Vector Machines (SVM)

第一种可以解决 regression 问题，后三种都是解决 classification 问题。

### Unsupervised Learning

这门课中针对三类问题讲了以下三种方法：

1. K-Means，用于聚类
2. Anomaly Detection（使用 Gaussian Distribution）
3. Collaborative filtering，用于推荐系统

以下将针对每一种方法进行简短的概述。

## Linear Regression

线性回归虽然并不适用于复杂的系统，但它的简洁明了适合我们去掌握 ML 中很多关键的概念。

首先我们要掌握的是 Hypothesis Function：

![Screen Shot 2016-08-22 at 10.46.46 AM.png](http://cdn.yyqian.com/201608221047-FrgHgRIsGoZKXDZvEPlilFSvvs8t?imageView2/2/w/800/h/600)

这个是适用于 Linear Regression 的假设函数，Linear 这个命名也来源于此，因为它是一个矩阵和向量的乘积。

假设函数的目的是根据输入 X 来计算预测值，而 sigma 就是参数，描述了我们的模型。

有了预测值，我们需要根据 Cost function

![Screen Shot 2016-08-22 at 10.52.44 AM.png](http://cdn.yyqian.com/201608221052-FmLpNuAechaq1EtnrfYcqUOp0Wsy?imageView2/2/w/800/h/600)

来计算预测的值和真实值之间的偏差，也称之为 cost。当然，我们希望这个 cost 越小越好，所以我们接下来要做的就是最小化这个 cost，而这里的变量就是 sigma。

最小化 Cost function 较为通用的方法是 Gradient descent：

![Screen Shot 2016-08-22 at 10.58.46 AM.png](http://cdn.yyqian.com/201608221059-FkJ_z4QRYAR_1Ce_HmwYWgu6TrF4?imageView2/2/w/800/h/600)

我们每次都沿着函数的切线方向，向谷底走一小步，直到达到谷底就完成了最小化的过程。对于 Linear Regression，我们得到的具体的计算公式如下：

![Screen Shot 2016-08-22 at 11.01.12 AM.png](http://cdn.yyqian.com/201608221101-Ft7nLcfdpVWWfN-1pOwm3qk3ivI1?imageView2/2/w/800/h/600)

实际上，对于线性回归这类特殊问题，我们是有解析解的，通过求逆矩阵等步骤，可以得到精确解，但是对于超大的矩阵，求逆矩阵这个步骤计算量特别大，所以解析的方法也是有局限之处的。

另外要注意的是，这里的线性不是指的只跟 X 的一次方相关，我们也可以引入高次幂，只要把高次幂作为新的 features 加入到 X 中即可。

## Logistic Regression

Logistic Regression 和 Linear Regression 的差别主要在于 Hypothesis Function，其他计算是类似的，但它虽然名字带 regression，其实是用来解决 classification 问题的。

Logistic Regression 的 Hypothesis Function 如下：

![Screen Shot 2016-08-22 at 11.51.19 AM.png](http://cdn.yyqian.com/201608221151-Fga3YXFvlgtPXDXaf9Wr20_PDDtv?imageView2/2/w/800/h/600)

它的输出是 0 到 1 之间的连续的数值，我们以 0.5 为分割点，将这个数值进一步二值化为 0 和 1，这就是我们最终的预测值（后面我们还能看到，这个分割点 0.5 是可以取其他值的）。

然后 Cost function 也需要进行一定的更改：

![Screen Shot 2016-08-22 at 12.10.47 PM.png](http://cdn.yyqian.com/201608221210-Fr6D8G8NcaHbokKVPNMAtz6oA7MY?imageView2/2/w/800/h/600)

如果这里还是用之前的 Cost function，会存在很多局部最小值，而这个对数形式的是只有全局最小值的。

最小化这个 cost function 的方法还是用 Gradient descent，更新的步骤是以下公式，这里已经计算好了导数的表达式：

![Screen Shot 2016-08-22 at 12.12.20 PM.png](http://cdn.yyqian.com/201608221212-FkDKRpQINvPDQkaN50CQYeW8p7IO?imageView2/2/w/800/h/600)

这个方法本质上只适用于二分类的问题，如果是多分类的问题，我们要用 One-vs-all 的技巧：例如我们有 A、B、C 三类，第一次计算的时候标记 A 为 0，B 和 C 为 1，后面两次计算交互顺序，所以实际上是做三次计算，得到三个预测模型，每个模型只能预测 X 和 非X。

## Neural Networks

Neural Networks 无疑是当下 ML 中比较火的算法，它通过模拟神经元组成的网络来构建模型。这里不具体讲这个算法了，只谈一下我对这个算法的理解。

前面的 Linear Regression 和 Logistic Regression 在模型的复杂度方面存在一定的局限性：我们在构造这些模型时选用的 features（也就是 X）往往只包含一次项，它们的高次幂以及交互项（例如 x_1*x_2）很有可能是完全忽略的（这一点可以从只包含一次幂或二次幂的平面曲线中可以看出）。

虽然我们可以通过添加新的高次幂或者交互项作为独立的 features 来将模型复杂化，但是这个过程是需要人为挑选的，一定程度上违背了「机器自动学习」的宗旨。

Neural Networks 在复杂度方面有非常大的优势，该模型中的隐藏节点实际上就是构造出来的新的 features，但这些 features 对我们来说是透明的，我们不需要也不允许去挑选新的 features。我们要做的是选择隐藏节点的层数和每层的节点数，这个实际上是在定义模型的复杂度，这显然比人为地挑选新的 features 要优雅地多。

除此之外，跟 Logistic Regression 相比，Neural Networks 天然支持多分类问题，只需要多个输出节点就可以了。

Neural Networks 的正向传播和反向传播算法这里就不多介绍了，计算量比其他算法大很多，但好在现在有 TensorFlow 等框架的支持，并行以及用 GPU 并行等技术可以很轻易地来加速这一算法的实现。

## General Advice

ML 中除了这些一个个用于解决某类问题的算法，还有很多较为普适的问题、分析方法和优化手段。

### Model Selection

前面我们提到了模型中有很多参数需要进行最优化计算，这其实是一类参数，还有一类参数是模型本身的：例如神经网络中的层数和节点数，线性回归中高次项的挑选以及后面我们要提到的 Regularization 中的 lambda 值的选择。这一类参数和数据集无关，只和我们模型的选择有关，所以我们实际还需要对模型本身做出一些选择。

### Train/Validation/Test Sets

在使用已有的数据集的时候，我们一般建议把数据集分成三类：

1. Train Set: 这个数据集是通过最小化 Cost function 来计算最优的 Sigma 参数的，针对每一种不同的模型我们都需要进行计算（包括不同模型参数）。
2. Cross Validation Set: 这个数据集用于 Model Selection，前面我们用 Train Set 训练好了所有的备选的模型，这个时候我们 CV 这一组数据集来测试这些模型的准确度，这样我们就能从中挑选最佳的模型了。
3. Test set：用该组数据集来计算我们最终选择的最优的模型的误差。

这三个数据集的比例一般建议为：6:2:2。

### Underfitting 和 Overfitting，Bias 和 Variance

如果我们的模型太简单（例如线性回归只包含了一次项），这个时候无论我们有多少精准的数据，都无法得到一个很好的模型，我们称之为欠拟合。它表现为测试集和交叉验证集得到的误差（也就是 cost function）都很大，我们称之为 high bias。这个时候我们改进的手段就是增加 features，让模型复杂化。

如果我们的数据太少或者 features 太多，这个时候可以很好地 fit 测试集，但无法很好地预测交叉验证集，我们称之为过拟合。它表现为测试集的误差很小，但交叉验证集得到的误差很大，我们称之为 high variance。这个时候我们改进的手段有获取更多的数据和合理地减少 features。

### Regularization

前面的过拟合问题我们还可以通过增加一个 Regularization 项来解决，例如对于逻辑回归：

![Screen Shot 2016-08-22 at 1.53.46 PM.png](http://cdn.yyqian.com/201608221354-FkVVQkZ2nW2FaoJFNrkpSxdS-vPa?imageView2/2/w/800/h/600)

我们可以通过调节这个 lambda 的大小，来控制 bias 和 variance 之间的权衡。过大的 lambda 会导致 underfitting，而过小的 lambda 有可能会导致 overfitting。这个调节可以通过 CV set 来设计程序自动选择最优的 lambda 值。

这一项的作用实际是在削弱模型中高次项的 features 对整体的影响，它是以 penalty 的形式加进来的。

### Learning Curve

Learning Curve 的示例图如下：

![Screen Shot 2016-08-22 at 2.05.17 PM.png](http://cdn.yyqian.com/201608221406-FsLetHIFI233G8OXjmmfOytdsQ7v?imageView2/2/w/800/h/600)

![Screen Shot 2016-08-22 at 2.06.09 PM.png](http://cdn.yyqian.com/201608221406-FtADQsEBhKIYJw3H6xbBJmC7RSNe?imageView2/2/w/800/h/600)

我们可以通过这个图诊断我们的模型存在哪些问题，以及如何针对这些问题进行改进。

### Precision and Recall

我们前面评判一个算法好坏以及 Model Selection 的时候，使用的评判指标是 Cost function 也就是误差。但这个不适用于 skewed classes，例如病人的诊断，可能 98% 的人都是正常的，只有 2% 是有病的。这个时候更适合参考的是 precision 和 recall，两者定义如下：

![Screen Shot 2016-08-22 at 2.10.21 PM.png](http://cdn.yyqian.com/201608221410-Fibr4h544-ZAYnIjagmumncZ7THc?imageView2/2/w/800/h/600)

两者结合能得到更合适的指标：

![Screen Shot 2016-08-22 at 2.13.31 PM.png](http://cdn.yyqian.com/201608221413-FmF1PqFLSHpYQ3y1mkUpOD7wOPv1?imageView2/2/w/800/h/600)

## Support Vector Machine (SVM)

SVM 和 Logistic Regression 有很多类似之处。它又称为 Large Margin Classification，训练得到的模型的边界比 Logistic Regression 更佳。

SVM 有 with kernal 和 witout kernal (linear kernal) 两个版本，linear kernal 的形式基本和 Logistic Regression 是一致的，有核的版本会在每个点作高斯函数的展开，计算量会大很多。所以我们需要根据 features 数目和数据集大小，来在这两个方法中做出选择。

## K-means

K-means 是用来解决一系列的聚类问题，将一个无标签的数据集分成若干类。这个算法的迭代分两步：

1. 对每个数据点，计算它到各个 cluster 中心的距离，选择最近的那个作为它的归属（也就是分类）
2. 对当前的每个分类，计算该分类所有数据点的平均值来作为新的 cluster 中心。

我们可以看出这实际上是一个较为简单明了的算法，我们额外还需要做的是设定多少个 cluster 中心（也就是要分成多少个类）？以及随机初始化这些 cluster centers 的位置。

初始化位置的不同也会导致最终的分类有所差别，所以这里也需要 CV set 来进行 Model Selection 的步骤。

## Principal Component Analysis（PCA）

PCA 是用来进行 Dimensionality Reduction 的一种方法，也可以用作 Data Compression（例如减少图片的颜色种类）、Visualization（将高维度的数据压缩到 2、3 维以便作图）。在我们的 ML 中，我们可以通过压缩维度来大大减小计算量。具体的算法就不做展开了。

## Anomaly Detection

Anomaly Detection 的思路其实很简单，用高斯分布来拟合数据集，概率小的数据点自然就很可能是异常的。

高斯分布表达式中的 mu 和 sigma 都是可以通过数据集训练出来的。这里的关键在于如何确定一个概率的阈值，小于这个阈值的数据点都被标为异常点。这个时候我们需要少量的带标签的异常数据，来「指导」我们对这个阈值做出选择。

既然我们用来带标签的数据集，这不就是 Supervised Learning 了么？这里的区别就在于异常数据集的大小，Anomaly Detection 只需要很少量的异常数据集来标定阈值，而 Supervised Learning 通常需要相同体量的正负样本数目。

## Recommender Systems

Recommender System 是被广泛使用的一种 ML 应用，采用一种称为 Collaborative Filtering 的算法来构造。这里直接给出 Cost function 和迭代步骤的表达式：

![Screen Shot 2016-08-22 at 2.52.36 PM.png](http://cdn.yyqian.com/201608221452-FlOcYo-KKwbJ-hq94Yf6gP6OyqfE?imageView2/2/w/800/h/600)

![Screen Shot 2016-08-22 at 2.52.28 PM.png](http://cdn.yyqian.com/201608221452-FtpF2iDC4p1MAWC8n5EalpQm-z7O?imageView2/2/w/800/h/600)

我们要注意的是这个算法里有 x 和 sigma 两种参数需要进行训练，两者之间也存在相互训练的关系。这个算法看似较为复杂，但在向量化之后，实际的计算表达式并不复杂。

## Large Scale Machine Learning

在人人都谈大数据的时代，动不动就是上亿的数据量会给我们之前讨论的算法都带来一些的问题。

### Gradient Descent 的变种

对于 Gradient Descent 这一训练步骤，迭代的每一步都需要遍历所有数据，这个对于大数据是不太适用的。因此有了 Stochastic Gradient Descent 算法，它的区别在于迭代步骤每次只随机选用了一个数据点：

![Screen Shot 2016-08-22 at 3.01.40 PM.png](http://cdn.yyqian.com/201608221501-FtftYoPW3r2a-YrY7VKTu89aQHHz?imageView2/2/w/800/h/600)

这个算法在优化的路径上是迂回前进的，但最终到达终点的速度要比我们之前的 Batch Gradient Descent 算法更快。

如果对这条迂回的路线不太满意，我们还可以用 Mini-Batch Gradient Descent，它的区别就在于迭代的时候选用了部分的数据集，作为 batch 和 stochastic 两者的折中方案：

![Screen Shot 2016-08-22 at 3.04.36 PM.png](http://cdn.yyqian.com/201608221504-FtmxsjOrv_NtTM7i2rHSttUXmZYn?imageView2/2/w/800/h/600)

### Online Learning

如果你听过 Streaming、Piplining 等字眼，应该可以理解我们的数据往往是向水流一样源源不断地流到我们系统中来的，而不是像这里一直在讨论的先准备数据集，再做划分等等 blabla。这个时候我们就要求算法能够实时地消化新的数据，动态地更新当前的模型，然后就把数据丢掉。

### 并行化

我们可以看到 ML 的算法中大量地用了累加，矩阵运算等操作，这些操作大多是可以并行计算的。并行的方式有多种，例如：

1. 利用 CPU 或 GPU 的多个核心，通过多线程来并行计算
2. 将数据集分成若干块，交个多个计算机处理，再汇集它们的处理结果，这也就是 Map-reduce 过程

这个课程里也经常强调使用向量化，目的之一也是利用软件平台内部实现的并行优化来进行一些常见的矩阵乘法等操作。

## 总结

个人觉得 Andrew Ng 的 Machine Learning 这门课程能够很好的让其他领域的学生让了解 ML 这个 AI 的分支，学习门槛较低，课程目的也是以了解这一领域能做什么，以及如何运用到实际的项目中为主。学完之后觉得也能做点小项目实践一下了。同时，这对于推广这门技术，让它发展更为迅速也很有帮助。
