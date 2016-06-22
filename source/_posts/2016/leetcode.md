---
title: LeetCode 解题思路汇总
date: 2016-06-16 23:33:33
permalink: 1466091213000
tags:
---

最近在用零碎的时间做做 LeetCode，锻炼下算法功底，这里把做过的题目的解题思路汇总一下。

**202. Happy Number**

这个题目难点在于寻找闭环，有三个解法：

1. 用链表的 runner 和 walker 方法来寻找闭环
2. 用一个 set 来记录出现过的数字，如果有重复的就说明有闭环
3. 如果有闭环，则闭环中必定有 4（证明方法未知），根据这点来判定

**350. Intersection of Two Arrays II**

解法一：

1. 先把两个数组各自排序
2. 用两个指针指向两个数组当前比较的位置，根据比较结果来移动指针和添加交叉值

解法二：

1. 用 hashtable 来记录数组 1 中每个数字出现的次数
2. 遍历数组 2，如果 hashtable 中存在当前元素就添加该元素，同时将哈希表中该元素的出现次数减一
<!-- more -->
**349. Intersection of Two Arrays**

解法一：用两个 set，数组 1 转换成 set，结果用 set 作为数据结构。然后遍历数组 2 进行比较，如果符合则加入结果的 set

解法二：跟 350 题的解法一类似，不同点是结果用 set 来作为数据结构

**231. Power of Two**

解法一：用 n & (n-1) trick

解法二：数一下 bit 为 1 的数目，符合的只会有 1 个

**326. Power of Three**

解法一：递归地检查余数，然后除以 3

解法二：3^19 = 1162261467 是 int 所能容纳的最大的符合条件的数，用它来进行取模操作。

**342. Power of Four**

326 的解法二在这行不通，因为 4 不是素数。

Power of Four 的特点是 bit = 1 的位置出现在奇数位，我们用以下步骤：

1. 先用 n & (n-1) trick 检查是否是 Power of Two
2. 然后检查 1 出现的奇偶位：检查 0b010101...010101 (也就是 0x55555555) & num 的结果是否为 0

**6. ZigZag Conversion**

用 numRows 长度的 StringBuilder 缓存每一行的字符，然后一个指针指 rows，一个指针指下一个字符。

**204. Count Primes**

参照 Sieve of Eratosthenes 算法

**7. Reverse Integer**

迭代地用 mod 10 取最低位，然后最低位 * 10 添加到结果中。麻烦的地方在于检查 overflow。

**9. Palindrome Number**

7 的解法可以用在这里，也同样要注意 overflow。

**146. LRU Cache**

实现 LRU 的方法：用双向链表（LinkedList）来存放每个数据节点，当访问某个节点的时候，把该节点从链表中删除，然后再添加到链表的头部。当链表满了，就把尾部的节点删除。

get 方法要做的事：访问 Map 获得 该 key 对应的节点，把该节点移到头部，返回该节点的值

put 方法要做的事：如果存在该 key， 则把访问的节点移到头部，并且更新该节点的值，然后返回；如果空间不足， 则删除尾巴处的节点，也同时从 Map 中删除，直到空间足够；如果空间足够，则创建新的节点，把该节点加到链表头部，并且在 Map 中也添加该 key。

**206. Reverse Linked List**

Linked List 正常添加节点都是添加到头部，我们遍历一遍 List，每次都往头部添加，自然就得到一个反序的 List 了

**92. Reverse Linked List II**

在 206 的基础上，我们需要略过头部不需要反序的部分，并且在交换的时候注意要维持尾部的链条。

**169. Majority Element**

有点 tricky，用一个计数器去计算当前猜测字符出现的次数，如果计数器归零，则换个数字。(Boyer-Moore Majority Vote algorithm)

**229. Majority Element II**

这个和 169 类似，用 Boyer-Moore Majority Vote algorithm

**8. String to Integer (atoi)**

核心的部分，就是用 charAt 取字符，减去字符 0，得到的就是数字了。这里要注意头尾空格，正负号，以及 int 溢出。

**14. Longest Common Prefix**
