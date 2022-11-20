# 借助Idea打包

https://blog.csdn.net/manqishizhizhu/article/details/121911423

主要是MANIFEST.MF文件要放在包的根目录下!





1. 首先打开 `Project Structure` > `artifacts` > `+` > `from modules ...`

   ![image-20211213180452951](%E5%80%9F%E5%8A%A9Idea%E6%89%93%E5%8C%85.assets/3bbba8fee2c8b772a8612af6dcbe1c1c.png)

2. 选择对应的模块和`Main class`

   ![image-20211213181316956](%E5%80%9F%E5%8A%A9Idea%E6%89%93%E5%8C%85.assets/b022ab41c117949a1554031dbec550cb.png)

3. **重点在 `Directory for META-INT/MANIFEST.MF` 要将其放置在项目的根路径**

4. 然后保存

5. 后面就可以在`build`菜单下进行打包


