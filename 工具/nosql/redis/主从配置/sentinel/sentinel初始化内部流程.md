# sentinel初始化内部流程

因为sentinel 本质上是一个特殊的redis 服务器

所以启动sentinel 的第一个就是初始化一个redis 服务器, 但因为sentinel 的工作模式和redis 的有所区别, 所以初始化过程和普通的redis 服务器并不完全相同

