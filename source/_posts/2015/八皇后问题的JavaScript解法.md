---
title: 八皇后问题的 JavaScript 解法
date: 2015-09-13 11:10:57
permalink: 1442113857711
tags: JavaScript
---

这里主要是借八皇后问题展示下JavaScript的强大表现力，整个程序都没用for循环，都是靠递归来实现的，充分运用了Array对象的map, reduce, filter, concat, slice方法。

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

2016-04-29 更新：

又用 ES6 的箭头函数改写了一下上面的程序，贴上来对比一下，貌似清爽了许多。

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
