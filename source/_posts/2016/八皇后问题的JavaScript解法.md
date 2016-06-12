---
title: 八皇后问题的 Clojure 和 JavaScript 解法
date: 2016-06-12 12:19:59
permalink: 1465705199000
tags: [Clojure, JavaScript]
---

最近在学习 Clojure，又写了个 Clojure 版本的八皇后解法。代码长度和箭头函数版的 JS 还是差不多的。

```Clojure
; Eight queens puzzle
(defn safe?
  "计算 a, b 两点的斜率, 如果斜率为 0, 1, -1, 无穷大的话, 则判定为 not safe"
  [a b]
  (if (= (second a) (second b))
    false
    (let [slope (/ (- (first a) (first b))
                   (- (second a) (second b)))]
      (not (or (= slope 0)
               (= slope 1)
               (= slope -1))))))

(defn valid?
  "检查新增的一列是否符合条件"
  [col]
  (let [len (count col)
        to-check [(last col) len]]
    (->> col
         (take (- len 1))
         (map-indexed (fn [index row] (safe? to-check [row (+ index 1)])))
         (reduce #(and %1 %2)))))

(defn queen-cols
  "递归地一列一列地添加新的符合条件的列"
  [col board-size]
  (let [rng (range 1 (+ board-size 1))]
    (if (<= col 1)
      (map #(vector %) rng)
      (->> (queen-cols (- col 1) board-size)
           (map (fn [col] (map #(conj col %) rng)))
           (reduce into)
           (filter valid?)))))

(defn queen
  [size]
  (queen-cols size size))

(queen 8)
```
<!-- more -->
用 ES6 的箭头函数改写的之前的代码。

```JavaScript
'use strict';
const queens = boarderSize => {
  // 用递归生成一个start到end的Array
  const interval = (start, end) => (start > end) ? [] : interval(start, end - 1).concat(end);
  // 检查一个组合是否有效
  const isValid = queenCol => {
    // 检查两个位置是否有冲突
    const isSafe = (pointA, pointB) => {
      const slope = (pointA.row - pointB.row) / (pointA.col - pointB.col);
      return (0 !== slope) && (1 !== slope) && (-1 !== slope);
    };
    const len = queenCol.length;
    const pointToCompare = {
      row: queenCol[len - 1],
      col: len
    };
    // 先slice出除了最后一列的数组，然后依次测试每列的点和待测点是否有冲突，最后合并测试结果
    return queenCol
      .slice(0, len - 1)
      .map((row, index) => isSafe({row: row, col: index + 1}, pointToCompare))
      .reduce((a, b) => a && b);
  };
  // 递归地去一列一列生成符合规则的组合
  // 先把之前所有符合规则的列组成的集合再扩展一列，然后用reduce降维，最后用isValid过滤掉不符合规则的组合
  const queenCols = size =>
    (1 === size)
      ? interval(1, boarderSize).map(i => [i])
      : queenCols(size - 1)
          .map(queenCol => interval(1, boarderSize).map(row => queenCol.concat(row)))
          .reduce((a, b) => a.concat(b))
          .filter(isValid);
  // queens函数入口
  return queenCols(boarderSize);
};

console.log(queens(8));
// 输出结果:
// [ [ 1, 5, 8, 6, 3, 7, 2, 4 ],
//   [ 1, 6, 8, 3, 7, 4, 2, 5 ],
//   ...
//   [ 8, 3, 1, 6, 2, 5, 7, 4 ],
//   [ 8, 4, 1, 3, 6, 2, 7, 5 ] ]

```

最早用 JavaScript 写的，用的递归解法：

```JavaScript
'use strict';
var queens = function (boarderSize) {
  // 用递归生成一个start到end的Array
  var interval = function (start, end) {
    if (start > end) { return []; }
    return interval(start, end - 1).concat(end);
  };
  // 检查一个组合是否有效
  var isValid = function (queenCol) {
    // 检查两个位置是否有冲突
    var isSafe = function (pointA, pointB) {
      var slope = (pointA.row - pointB.row) / (pointA.col - pointB.col);
      if ((0 === slope) || (1 === slope) || (-1 === slope)) { return false; }
      return true;
    };
    var len = queenCol.length;
    var pointToCompare = {
      row: queenCol[len - 1],
      col: len
    };
    // 先slice出除了最后一列的数组，然后依次测试每列的点和待测点是否有冲突，最后合并测试结果
    return queenCol
      .slice(0, len - 1)
      .map(function (row, index) {
        return isSafe({row: row, col: index + 1}, pointToCompare);
      })
      .reduce(function (a, b) {
        return a && b;
      });
  };
  // 递归地去一列一列生成符合规则的组合
  var queenCols = function (size) {
    if (1 === size) {
      return interval(1, boarderSize).map(function (i) { return [i]; });
    }
    // 先把之前所有符合规则的列组成的集合再扩展一列，然后用reduce降维，最后用isValid过滤掉不符合规则的组合
    return queenCols(size - 1)
      .map(function (queenCol) {
        return interval(1, boarderSize).map(function (row) {
          return queenCol.concat(row);
        });
      })
      .reduce(function (a, b) {
        return a.concat(b);
      })
      .filter(isValid);
  };
  // queens函数入口
  return queenCols(boarderSize);
};

console.log(queens(8));
// 输出结果:
// [ [ 1, 5, 8, 6, 3, 7, 2, 4 ],
//   [ 1, 6, 8, 3, 7, 4, 2, 5 ],
//   ...
//   [ 8, 3, 1, 6, 2, 5, 7, 4 ],
//   [ 8, 4, 1, 3, 6, 2, 7, 5 ] ]

```
