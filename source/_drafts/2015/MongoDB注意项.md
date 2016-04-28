---
title: MongoDB注意项
date: 2015-04-15 17:47:42
permalink: 1429091262327
tags:
---

## Daemon

`mongod --fork --logpath /var/log/mongodb.log`

## Read

`db.collection.find({query criteria}, {projection}).Modifier()`

Modifier can be sort, limit, skip(not suggested)

Example:

`db.users.find( { age: { $gt: 18 } }, { name: 1, address: 1 } ).sort({age: -1}).limit(5)`

> Except for excluding the _id field in inclusive projections, you cannot mix exclusive and inclusive projections.

_id field is implicitly included

## Consideration

1. read-to-write ratio
  * high: denormalize
  * medium: normalize (because it's easier to maintance)
  * low: normalize
2. one-to-N
  * N is small: denormalize (Embed the N-side in the one-side)
  * N is medium: normalize (Put an **array of references to the N-side** in the **one-side**)
  * N is large: normalize (Put a **reference to the one-side** in the **N-side**)
  


