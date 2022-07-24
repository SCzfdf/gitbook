# 关于sh 和bash 

[\#!/bin/bash和#!/bin/sh的区别](https://blog.csdn.net/m0_37806112/article/details/88368900)



使用`ENTRYPOINT  [ "/bin/bash", "-c", "/docker-entry.sh ${VAR}" ]` 时有时候会提示说找不到sh/bash 命令

那是因为有些系统支持的标准不一样

**SH**：

sh就是Bourne shell
这个是UNIX标准的默认shell，对它评价是concise简洁 compact紧凑 fast高效，由AT&T编写，属于系统管理shell

**BASH**:

bash是 GNU Bourne-Again SHell (GNU 命令解释程序 “Bourne二世”)
是linux标准的默认shell ，它基于Bourne shell，吸收了C shell和Korn  shell的一些特性。bash是Bourne shell的超集，bash完全兼容Bourne shell,也就是说用Bourne  shell的脚本不加修改可以在bash中执行，反过来却不行，bash的脚本在sh上运行容易报语法错误。



一些系统会把sh设置为bash的软连(如centos)

有一些系统只会单独实现sh



如果遇到`/bin/sh` 报错试下`/bin/bash`

