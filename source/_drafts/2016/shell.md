---
title: Shell Command List
tags: shell
---

```shell
# 取用变量
echo $HOME
echo ${HOME}

# 设定变量，等号两边不能有空格，建议用单引号或双引号
myname="I'm Tony Stark"
echo $myname

# 累加内容
myname="${myname}. Iron Man!"
echo $myname

# 单引号不会取变量值
myname='${myname}. Iron Man!'
echo $myname

# 取消变量
unset myname
echo $myname

# 反引号 ` 或者$()可以让命令优先执行
echo `uname -r`
echo $(uname -r)

# 用 \ 分行，注意空格
echo \
$PATH

# env 获取环境变量，set 获取环境变量 + 自定义变量
env
set

# 读取键盘输入, 存入变量
read atest
echo $atest

# 变量类型声明，如果我们的变量是非字符串类型，这个就是必须的
sum=100+200
echo $sum
declare -i sum=100+200
echo $sum

# export 的功能是将某个变量变成环境变量，并传递到子进程中
testname="Star Trek"
export testname
bash # 这个时候进入子 Bash，测试下 $testname，在 bash 子程序中可以使用

# 数组
var[1]="MBP 13"
var[2]="MBP 15"
var[3]="Server"
echo "${var[1]}, ${var[2]}, ${var[3]}"

# 数值运算：+ - * / %
echo $(( 13 % 3 ))

# for
for i in 1 10 100
do
    echo "Welcome $i times"
done

for i in {0..10..2}
do
    echo "Welcome $i times"
done

for X in *.html
do
   echo $X
done

# while
while [ condition ]
do
    #程序段落
done

# if
if condition1
then
    statement1
    statement2
elif condition2
then
    statement3
    statement4
else
    statement5
    statement6
fi

# function
function fun(){
    echo "Calling a Function $1"
}
fun MOD

# test
if [ -f README.md ]
then
    echo "exists"
fi

# -n    operand non zero length 1
# -z    operand has zero length 1
# -d    there exists a directory whose name is operand  1
# -f    there exists a file whose name is operand   1
# -eq   the operands are integers and they are equal    2
# -neq  the opposite of -eq 2
# =     the operands are equal (as strings) 2
# !=    opposite of =   2
# -lt   operand1 is strictly less than operand2 (both operands should be integers)  2
# -gt   operand1 is strictly greater than operand2 (both operands should be integers)   2
# -ge   operand1 is greater than or equal to operand2 (both operands should be integers)    2
# -le   operand1 is less than or equal to operand2 (both operands should be integers)   2
```