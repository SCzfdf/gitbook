# WebService 与socket

[socket和webservice区别，他们各自有什么优缺点？](https://www.zhihu.com/question/20263931)



socket 基于TCP/IP 的传输层协议

WebService 是基于http 协议传输数据



Socket接口通过流传输，不支持面向对象。Web Service 接口支持面向对象，最终webservice将对象进行序列化后通过流传输。



WebService 适用于传输大数量的数据，缺点：接口传输的数据需要手动解析，socket通信的接口协议需要自定义。WebService适用于没有性能要求情况下且数据传输量小，推荐在公开接口上使用webservice，因为它继续标准的soap协议.

