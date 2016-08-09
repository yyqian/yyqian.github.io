---
title: LeetCode 解题思路汇总
date: 2016-06-16 23:33:33
permalink: 1466091213000
tags:
---

最近在用零碎的时间做做 LeetCode，锻炼下算法功底，这里把做过的题目的解题思路汇总一下。

当前免费的题目有 286 题（2016/07/07），各难度总数统计：

- Easy: 78
- Medium: 142
- Hard: 66

当前已完成的统计（2016/07/07）：

- Easy: 48
- Medium: 49
- Hard: 3

未完成统计：

- Easy: 30
- Medium: 93
- Hard: 63

按照每天 1 Easy, 3 Medium, 1 Hard 的题量，30 天可以清空所有免费的 Easy 和 Medium。

## 总结一些技巧和注意点

### 注意处理特殊情况

除数为零，输入为 null，数组/列表长度为零，int 溢出

### 列表问题的技巧

- runner 和 walker 用来探测闭环
- 用 sentinel 来记录头部，适当的时候也记录下尾部。

### 数组问题

- 用若干个指针来记录和移动
- 先排序试试(一般 nlgn 复杂度)
- [Maximum subarray problem](https://en.wikipedia.org/wiki/Maximum_subarray_problem)

### 数字问题技巧

- x & (x - 1) 来判断是否为 2 的 n 次方
- 利用 Prime Number 的性质
<!-- more -->
### 常见算法应用

1. DP
2. dfs 和 bfs
3. 二分搜索
4. 分治
5. hashtable
6. 用迭代 + stack/queue/array 来取代递归

经典题目汇集：

137, 148, 210, 208, 215, 221

### 技巧

- dfs: 把路径集合传到递归函数中，在递归之前 push 元素，递归之后 pop 元素，这个路径就可以反复利用
- bfs: 对于深度，可以用 queue，进入下一层的时候，先获取当前 queue 的大小 n，然后循环 n 次，把这一层的元素都处理完，这时候层级++，进入下层迭代。见 127 题。

## 各个题目的解题思路

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

**77. Combinations**

自己的做法：用分治法，C(n,k) = C(n-1,k-1) + C(n-1,k)

combine(n, k) 的结果可以由两部分组成：

1. 组合里有元素 n: combine(n - 1, k - 1) 的每个组合都加上元素 n
2. 组合里没有元素 n: combine(n - 1, k)

考虑边界情况，把以上两个组合合并

**54. Spiral Matrix**

**59. Spiral Matrix II**

有两种方法：

1. 一圈一圈走，从最外圈往内圈走，每圈可以看成一次迭代
2. 用上下左右四个指针维持接下来要走的路径，每走完一条边，相应的指针就移动一格。

**341. Flatten Nested List Iterator**

用 Stack 来存储，如果栈顶是数组，就把它解开来 push 到 Stack 中，迭代直到栈顶是单个数字。

**55. Jump Game**

可以用深度优先搜索来解决：把每个索引当做一个顶点，顶点的值决定了可以连接的后面的顶点。但这个算法不是最优的，会超时。

高效的做法是：从结尾出发，我们用一个 last 变量来保存最近一次能到达的点，如果当前点能到达 last 点，我们就把这个点设定为 last。前面的点如果连 last 点也到达不了，last 之后的点就更到达不了，所以只要与 last 进行比较就行。

```Java
public class Solution {
    public boolean canJump(int[] nums) {
        int last = nums.length - 1;
        for (int i = nums.length - 2; i >= 0; i--) {
            if (i + nums[i] >= last) last = i;
        }
        return last <= 0;
    }
}
```

**45. Jump Game II**

同 55，可以考虑用广度优先搜索来做，用 edgeTo 数组来保存路径，最后数一下所走的路径，可以 AC，但效率比较低。

更聪明的做法是，遍历数组，计算每个点能到达的最远距离，用一个 max 变量维持当前 level 所能到达的最远距离，如果当前 level 已经到达边界的时候，用 max 来设定下一个 level 的边界。

**166. Fraction to Recurring Decimal**

回想一下你是如何手动算除法的。

**14. Longest Common Prefix**

不排序的做法：先计算 0，1 两个位置的字符串的 lcp，然后遍历后面的字符串，跟 lcp 比较得到新的 lcp

排序的做法：先排序，然后直接计算第一个和最后一个的 lcp

**347. Top K Frequent Elements**

用一个 Map 来统计每个数字的频率，然后用桶排序，每个桶对应一个频率，桶的大小是数组大小加一（因为频率可以是 0 ~ N），一组桶用 List<Integer>[] 来表示，每个桶的链表上挂对应频率的数字。然后从每个桶挨个取就可以了。

**111. Minimum Depth of Binary Tree**

用递归法，注意要处理左右节点是否为 null 组合成的四种情况。

**19. Remove Nth Node From End of List**

用一个落后 n + 1 的指针跟随当前指针移动，当当前指针指向最后一个元素的时候，落后的指针的下一个就是要移除的元素。

**2. Add Two Numbers**

构造两个 Node，sentinel 用来记录头部，pre 用来记录上一个 Node，这样就能向尾部添加新的元素，需要注意的就是进位问题

**3. Longest Substring Without Repeating Characters**

利用哈希表存储字符和索引的关系，并维护指向符合条件字符串头尾的两个指针。

**5. Longest Palindromic Substring**

遍历所有字符，将单个或相邻两个字符进行展开，获得最大的长度。

**11. Container With Most Water**

用两个指针，一个指头部，一个指尾部，计算完面积之后，如果头部的高度小于尾部的高度，则头部的指针右移（因为此时尾部指针左移不可能得到比当前更小的面积）；反之尾部的指针左移。

**70. Climbing Stairs**

动态规划，DP

**121. Best Time to Buy and Sell Stock**

**53. Maximum Subarray**

以上两题参照：[Maximum subarray problem](https://en.wikipedia.org/wiki/Maximum_subarray_problem)

**122. Best Time to Buy and Sell Stock II**

改动之后这题很简单，如果我们把股价变动的图画出来，只要将所有的正数求和就可以了。

**62. Unique Paths**

有两个方法：

1. 用 DP，P(m, n) = P(m-1, n) + P(m, n-1)
2. 总共需要 m-1 次向下，n-1 次向右，总的步数是 m+n-2，结果就是 C^(n-1)_(m+n-2)

**63. Unique Paths II**

62 题排列组合的方法貌似不适用了，所以只能用 DP，节省空间的做法是利用参数的矩阵来存 DP 的中间结果，这样就不需要额外的空间复杂度了。

**64. Minimum Path Sum**

虽然这题貌似可以用 dijkstra 来解决，但实际 overkill 了，只要从左到右、从上到下遍历一遍，每个经过的顶点都不可能再被访问一遍，然后用贪心算法，局部作出最优选择就可以了。

**96. Unique Binary Search Trees**

假设计算 BST 个数的函数是 G(n), 以某个数字 i 为根的树的个数为 F(i, n)。我们可以得到 `G(n) = F(1, n) + F(2, n) + ... + F(n, n)`。数字 i 的两个分支分别是 1,...,i-1 和 i+1,...,n 组成的两棵树，因此 F(i, n) = G(i-1) * G(n-i)。最后，我们得到：

`G(n) = G(0) * G(n-1) + G(1) * G(n-2) + … + G(n-1) * G(0)`

**95. Unique Binary Search Trees II**

跟 96 题思路类似，不过这里不能用迭代法，只能用递归：选一个数字作为根，分成两个数字连续的分支，同样是 DP 的思维。

**15. 3Sum**

**16. 3Sum Closest**

以上两个问题类似，没什么很巧妙的办法，先排序，从左到右一个个检查，选定一个之后，剩余的序列中，用两个指针一个指头部，一直指尾巴，N^2 的复杂度。


**18. 4Sum**

类似 3Sum，但是这里要多一重循环，头部需要两个指针，尾部也需要两个指针，复杂度是 N^3。

**22. Generate Parentheses**

这题看似可以用 DP，实际上用 DP 解太复杂了。我们只要一笔一笔往下写，每一笔都会有可能出现两个分支：写左括号或者右括号，但这两个分支不一定有效，写右括号的时候当前的左括号数目必须大于当前右括号数目。

**20. Valid Parentheses**

用一个 stack，遇到左括号就入栈，遇到右括号就从出栈并检查是否匹配。

**21. Merge Two Sorted Lists**

可以用递归做，也可以用迭代做。

**24. Swap Nodes in Pairs**

用递归做最简单，处理头部两个节点，剩下的就递归。

**17. Letter Combinations of a Phone Number**

可以用分治法，合并分割后的两个结果。

**26. Remove Duplicates from Sorted Array**

**27. Remove Element**

以上两个类似。比较简单，计数器既可以作为结果，又可以用来作为记录当前能填充位置的指针。

**28. Implement strStr()**

就是 substring 的算法，可以用 KMP，如果 KMP 复杂的话就用暴力解法。

**29. Divide Two Integers**

除法的部分可以用位左移操作，用类似二分搜索的办法来寻找结果。还有个 tip 就是把 int 转换为 long 进行内部操作，在得到结果之后，再根据结果判断是否要给出溢出异常。

**31. Next Permutation**

我的做法是先找到需要替换的最左的位置，然后替换合适的数字，替换完之后有个一截需要反转下顺序。这里要注意观察序列的排序情况。

**34. Search for a Range**

lgN 复杂度的一般只有用二分搜索，这里的二分搜索在匹配之后，要记录当前位置，然后继续向两边进行二分搜索，试图找到该 Target 的边界。

**35. Search Insert Position**

还是用二分搜索，关键点是在不匹配的情况下，从最后一次比较中得到应当插入的位置。

**36. Valid Sudoku**

可以定出左上角和右上角两个顶点，然后三种情况可以用同一个函数进行判断。

**38. Count and Say**

比较简单。每次都判断下一个字符是于当前相同，然后有计数器计数相等的个数。

**39. Combination Sum**

**40. Combination Sum II**

40 题可以用 DFS，但特别要注意的是重复元素的问题，谨慎处理相同元素节点之间的跳转。

**43. Multiply Strings**

用我们手算的方法去做，构造一个数组，记录每一位的数字，注意处理进位。

**46. Permutations**

分治法。

**47. Permutations II**

用 dfs，配合 path 列表和 used 数组，这里有个诀窍是传入利用类似堆栈的形式重复利用 path 列表。

**48. Rotate Image**

有两种 in-place 方法：

1. 每个点旋转四次后都会回到原来的位置，所以可以以四个点为一组进行 swap
2. 旋转是翻转和转置的组合，翻转和转置都可以很容易地 in-place 进行

**49. Group Anagrams**

第一步：如果把字符串转换成字符数组，然后字符转 int 之后求和，如果是 Anagrams，求和肯定相同，但反过来不一定，这个相当于是在计算 hashCode，但可能会发生 hash collision
第二步：设计一个不会发生 collision 的 hash function，思路就是用 prime number，把 24 个英文字母映射到不同的 prime number，然后连乘得到 hashCode

**50. Pow(x, n)**

递归，n 每次降一半

**58. Length of Last Word**

很奇怪的题目，特别简单

**61. Rotate List**

可以把它变成一个环，然后在合适的地方把环断开。

**60. Permutation Sequence**

对于第一个字符我们是可以计算出来的，计算出来之后我们把它添加到结果，然后处理下一个字符，下一个字符的位置可以是看做一个 subarray，这时候字符集少了一个字，我们可以在最初用一个有序的 list 来保存当前尚未用过的数字，用完后把它移除。

**66. Plus One**

比较简单，一个小 trick 是如果最高为进位，只有可能是整个序列是 999999, 这个时候只要新建一个数组，然后最高为设置为 1 就可以了，余下的都是 0。

**67. Add Binary**

我们可以用 XOR 和加法来判断当前位和进位的数字。

**69. Sqrt(x)**

用二分搜索，注意 overflow

**71. Simplify Path**

用 stack，类似状态机，遇到 / 就 push，pop 或什么都不做。

**73. Set Matrix Zeroes**

我们先遍历一遍看看哪些位置是零，这里的 trick 是我们可以不用 Set 来存这些零点的位置，只要把这个点所在行或者列的头部标为 0 即可，用这个点来存放信息。

**74. Search a 2D Matrix**

二分搜索，把二维数组还原成一维就行。

**75. Sort Colors**

在头尾各用一个指针，在遍历数组的时候，遇到 0 就向头部 swap，遇到 2 就向尾部 swap。

**78. Subsets**

用迭代，一个个元素加上去

**90. Subsets II**

当有重复元素的时候，我们先数一下有几个重复的，然后在原有的结果上，添加 1 个重复的元素、添加 2 个。。。直到添加所有的重复元素。然后再处理下一个元素。

**89. Gray Code**

解法一：迭代，在(n - 1)的基础上加一个 0 或者 1。

![](https://upload.wikimedia.org/wikipedia/commons/c/c1/Binary-reflected_Gray_code_construction.svg)

解法二：直接用公式：G(i) = i^ (i/2)，暂时还没研究为什么这个公式可行。[wiki](https://en.wikipedia.org/wiki/Gray_code)

**91. Decode Ways**

DP，把字符挨个往上加，迭代更新结果。

**86. Partition List**

维护两个 List，一个存放小于 x 的元素，另一个存放大于等于 x 的元素，遍历完之后把它们接起来。维护这两个 List 的时候用四个指针指向它们的头尾。

**101. Symmetric Tree**

递归

**94. Binary Tree Inorder Traversal**

**144. Binary Tree Preorder Traversal**

**145. Binary Tree Postorder Traversal**

递归法，这个方法最容易揭示这几个遍历方法的本质

```Java
// Inorder
public class Solution {
    public List<Integer> inorderTraversal(TreeNode root) {
        List<Integer> res = new ArrayList<>();
        addInorder(root, res);
        return res;
    }
    private void addInorder(TreeNode root, List<Integer> res) {
        if (root == null) return;
        addInorder(root.left, res);
        res.add(root.val);
        addInorder(root.right, res);
    }
}

// Preorder，只要在前面的基础上改下递归函数
    private void preAdd(TreeNode root, List<Integer> res) {
        if (root == null) return;
        res.add(root.val);
        preAdd(root.left, res);
        preAdd(root.right, res);
    }

// Postorder，同上
    private void postAdd(TreeNode root, List<Integer> res) {
        if (root == null) return;
        postAdd(root.left, res);
        postAdd(root.right, res);
        res.add(root.val);
    }
```

迭代法

```Java
// Inorder
public class Solution {
    public List<Integer> inorderTraversal(TreeNode root) {
        List<Integer> res = new ArrayList<>();
        Deque<TreeNode> stack = new LinkedList<>();
        while (root != null || !stack.isEmpty()) {
            while (root != null) {
                stack.push(root);
                root = root.left;
            }
            root = stack.pop();
            res.add(root.val);
            root = root.right;
        }
        return res;
    }
}

// preorder
public class Solution {
    public List<Integer> preorderTraversal(TreeNode root) {
        List<Integer> res = new ArrayList<>();
        if (root == null) return res;
        Deque<TreeNode> stack = new LinkedList<>();
        stack.push(root);
        while (!stack.isEmpty()) {
            root = stack.pop();
            res.add(root.val);
            if (root.right != null) stack.push(root.right);
            if (root.left != null) stack.push(root.left);
        }
        return res;
    }
}

// postorder: postorder 的顺序是 left-right-root，而 preorder 的顺序是 root-left-right。我们先求 postorder 的倒序：root-right-left，这个只要在 preoder 算法基础上稍微改下就行，然后把结果倒序。
public class Solution {
    public List<Integer> postorderTraversal(TreeNode root) {
        List<Integer> res = new LinkedList<>();
        if (root == null) return res;
        Deque<TreeNode> stack = new LinkedList<>();
        stack.push(root);
        while (!stack.isEmpty()) {
            root = stack.pop();
            res.add(root.val);
            if (root.left != null) stack.push(root.left);
            if (root.right != null) stack.push(root.right);
        }
        Collections.reverse(res);
        return res;
    }
}
```

**79. Word Search**

用递归一个个字去检查，可以用 marked 数组来保存访问过的字，也可以用 ^ 256 来把访问过的字转换为不符合规范的，递归回来之后再 ^ 256 就恢复了。

**80. Remove Duplicates from Sorted Array II**

对于这种数组，不需要 swap，只要赋值过去就可以了。另外，用变量 i 维持下个添加的位置，判断是否要往头部添加的判断条件是当前值 n 是否等于 nums[i-2]

```
public class Solution {
    public int removeDuplicates(int[] nums) {
        int i = 0;
        for (int n : nums) {
            if (i < 2 || n != nums[i - 2]) nums[i++] = n;
        }
        return i;
    }
}
```

**116. Populating Next Right Pointers in Each Node**

定义一个辅助的递归方法，参数是两个相邻元素，把两者连起来，然后递归地调用它们的子节点。

**33. Search in Rotated Sorted Array**

两种解法：

1. 比较笨的：我们可以做两次二分搜索，一次用来查找起点，第二次用来查找元素。

2. 我们还是正常做二分搜索，每次分成两部分之后，必定会有一部分是升序的，这一点是关键。有了这一点，我们可以在这一部分中轻松地判断 target 是否在其中，如果不在，则在另一部分。其他的跟正常的二分相同，就是判断条件稍微多点。

**81. Search in Rotated Sorted Array II**

同 33 题，分成两部分，判断哪一部分是升序的，但不同点是：分成两部分之后，有可能两部分都不是升序的（因为有重复元素），这个时候一种选择是把两部分都做二分搜索，用递归法比较容易达到这点。

**82. Remove Duplicates from Sorted List II**

这题用递归思路最清晰。

**93. Restore IP Addresses**

类似 DFS 的做法，递归地遍历所有可行的下一个节点

**98. Validate Binary Search Tree**

我的做法是用 inorder 遍历，二叉搜索是的中序遍历得到的数组应当是有序的（从小到大）。

最好的做法是用递归，递归函数传入值的下界和下界。这样遍历一遍就能完成。

**102. Binary Tree Level Order Traversal**

**107. Binary Tree Level Order Traversal II**

BST，用一个 Queue，不过这儿需要每一层都中断一下。

**103. Binary Tree Zigzag Level Order Traversal**

我的解法同 102，只是把 Queue 改用 Stack，还有先加左元素还是右元素需要根据层级判断一下

**105. Construct Binary Tree from Preorder and Inorder Traversal**

**106. Construct Binary Tree from Inorder and Postorder Traversal**

很经典，有助于更深入理解这几种遍历。比较明了的方法是，用一个 HashMap 保存 inorder 数组的映射，然后利用结构，递归地构造左分支和右分支

**108. Convert Sorted Array to Binary Search Tree**

二分和递归

**109. Convert Sorted List to Binary Search Tree**

可以用个 HashMap，仍然用二分和递归做，但这样得遍历两次

更好的做法是反向的中序遍历，需要增加一个 ListNode 属性。

**110. Balanced Binary Tree**

递归检查两棵子树的高度是否差值大于 1

**112. Path Sum**

递归

**113. Path Sum II**

dfs，反复利用 Stack 形式的 path 变量（用来存储路径）

**114. Flatten Binary Tree to Linked List**

用 preorder 遍历一遍，递归的函数返回最后一个节点，这样可以把左右两个分支连接起来。

更简单的方法是用反向的 preorder，先探到末端，再从方法栈中一级级退出并连接之前的节点。

```
public class Solution {
    TreeNode prev;
    public void flatten(TreeNode root) {
        if (root == null) return;
        flatten(root.right);
        flatten(root.left);
        root.right = prev;
        root.left = null;
        prev = root;
    }
}
```

**118. Pascal's Triangle**

**119. Pascal's Triangle II**

简单地迭代或递归。

**120. Triangle**

用递归的 DP 很简单，不过效率太低，很多重复计算。所以要改成迭代，我们从下向上计算，每次只需要保存前一行的结果，所以空间复杂度是 O(n)

**125. Valid Palindrome**

取头取尾，略过非字母或数字（用 Character.isLetterOrDigit 判断），迭代验证。比较简单。

**129. Sum Root to Leaf Numbers**

递归

**130. Surrounded Regions**

只有 O 连到边界上时，才不会被 X 包围，所以当遍历到边界上的 O 时，用 BFS 探索所有与之连接的 O，标记为 B。完事之后，再遍历一次，把 B 变成 O，O 变成 X。

**131. Palindrome Partitioning**

类似 DP，我们从头部开始在不同的地方做第一次切分，右半部分递归地继续切分，左半部分不用再切分，但必须保证是 Palindrome

**134. Gas Station**

本质上和 Maximum subarray problem 类似，见 121 和 53

**127. Word Ladder**

推荐，典型的 BFS

**133. Clone Graph**

DFS，可以用 map 缓存访问过的节点

**136. Single Number**

推荐，微软面试那本书上有，XOR 满足交换率，A ^ A = 0, A ^ 0 = A

**137. Single Number II**

推荐，这个题很精彩，用数字电路设计以及状态机的思路来解，整体思路就是设计个计数器

**139. Word Break**

DP 或分治，递归版本会超时，用迭代

**143. Reorder List**

一个技巧是用 walker 和 runner 去找中间点

**147. Insertion Sort List**

就是插入排序，从头开始一个个检查。

**148. Sort List**

推荐，List 版本的 Merge Sort

**153. Find Minimum in Rotated Sorted Array**

二分搜索

**155. Min Stack**

用偏差

**152. Maximum Product Subarray**

除了全局最大值，还需要记录局部最大值、最小值

**160. Intersection of Two Linked Lists**

一条遍历完之后就遍历另外一条，这样下一次就会在交点汇合

**165. Compare Version Numbers**

先 split，然后遍历，如果超过数组大小的，按 0 处理

**168. Excel Sheet Column Title**

注意并不是从 0 开始的

**172. Factorial Trailing Zeroes**

只有可能 2 * 5 才能得到 0，由于 2 的数量原大于 5，所以 0 的数量取决于 5 的数量，5 的数量计算公式为 n/5 + n/(5^2) + n/(5^3) + ...

**173. Binary Search Tree Iterator**

用 stack 实现中序遍历，相当于是迭代版的中序遍历

**179. Largest Number**

定义一个 Comparator，用 Arrays.sort 来排序

**187. Repeated DNA Sequences**

用 tail substring 会超过限制 memory。可以用两个 set，一个存出现过的，一个存结果

**189. Rotate Array**

in-place 的一种做法是三次倒序。

**199. Binary Tree Right Side View**

BFS

**190. Reverse Bits**

先挪到最低位与 1 进行 AND 操作，再挪到正确的位置

**200. Number of Islands**

用 DFS，标记走过的路径

**201. Bitwise AND of Numbers Range**

如果两者不等，说明至少最后一位会被置零，然后两个数字

**203. Remove Linked List Elements**

很简单

**213. House Robber II**

**198. House Robber**

标准的 DP，注意要用迭代，不要用递归。迭代只需要保存前两项：include, exclude

**207. Course Schedule**

**210. Course Schedule II**

推荐。我用的是 DFS，也是 algorithm 红书上的算法。

```
public class Solution {
    private boolean[] marked;
    private boolean[] onStack;
    private boolean hasCycle = false;
    private List<List<Integer>> graph;
    
    public int[] findOrder(int numCourses, int[][] prerequisites) {
        Queue<Integer> queue = new LinkedList<>();
        marked = new boolean[numCourses];
        onStack = new boolean[numCourses];
        graph = new ArrayList<>();
        for (int i = 0; i < numCourses; i++) {
            graph.add(new ArrayList<Integer>());
        }
        for (int[] edge : prerequisites) {
            graph.get(edge[0]).add(edge[1]);
        }
        // 这个循环是真正的 dfs 操作
        for (int i = 0; i < numCourses; i++) {
            if (!marked[i]) dfs(i, queue);
        }
        int[] result = new int[queue.size()];
        int i = 0;
        while (!queue.isEmpty()) {
            result[i] = queue.poll();
            i++;
        }
        return hasCycle ? new int[0] : result;
    }
    private void dfs(int v, Queue<Integer> queue) {
        onStack[v] = true;
        marked[v] = true;
        for (int i : graph.get(v)) {
            if (hasCycle) {
                return;
            } else if (onStack[i]) {
                hasCycle = true;
            } else if (!marked[i]) {
                dfs(i, queue);
            }
        }
        queue.offer(v);
        onStack[v] = false;
    }
}
```

**208. Implement Trie (Prefix Tree)**

标准的 Trie 树

**209. Minimum Size Subarray Sum**

两根指针，分别指头尾，一直维持范围最小

**205. Isomorphic Strings**

用一个数组存储最近一次出现该字母的位置

**211. Add and Search Word - Data structure design**

推荐，Trie 树的实现，用递归比较容易做，因为遇到 . 需要产生多个递归操作，如果迭代的话就需要使用一个队列了。

```
public class WordDictionary {
    
    private Node root = new Node();
    
    private class Node {
        boolean hasWord = false;
        Node[] next = new Node[26];
    }

    // Adds a word into the data structure.
    public void addWord(String word) {
        Node node = root;
        for (char c : word.toCharArray()) {
            int i = c - 'a';
            if (node.next[i] == null) node.next[i] = new Node();
            node = node.next[i];
        }
        node.hasWord = true;
    }

    // Returns if the word is in the data structure. A word could
    // contain the dot character '.' to represent any one letter.
    public boolean search(String word) {
        if (word == null || word.length() == 0) return false;
        return search(word.toCharArray(), 0, root);
    }
    
    private boolean search(char[] word, int start, Node head) {
        if (start == word.length) return head.hasWord;
        char c = word[start];
        if (c == '.') {
            for (Node x : head.next) {
                if (x != null && search(word, start + 1, x)) return true;
            }
            return false;
        } else {
            return (head.next[c - 'a'] != null) && search(word, start + 1, head.next[c - 'a']);
        }
    }

}
```

**215. Kth Largest Element in an Array**

推荐。这个是用 QuickSelect 算法，类似 QuickSort，细节需要好好处理，

**216. Combination Sum III**

bakctracking, 跟 dfs 类似，用一个 stack 来记录 path。

**219. Contains Duplicate II**

用 Map 或 Set 都可以，Set 更高效：把超出范围的删除，如果新增元素不成功，说明范围内有重复。

**220. Contains Duplicate III**

可以用 TreeSet，借助它的 ceiling, floor 方法，复杂度是 Nlgk。

**221. Maximal Square**

推荐。DP 的思路

**222. Count Complete Tree Nodes**

我们在递归暴力求解的基础上进行改进。用二分查找的思路（但不是真正的二分查找），我们检查最左和最右的深度，如果相等，说明是满的，这时可以直接返回整颗树的节点数目。

**223. Rectangle Area**

关键是 overlaping 区域的坐标计算。