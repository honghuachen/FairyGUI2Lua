# FairyGUI2Lua
这是FairyGUI编辑器插件，用于发布导出FairyGUI包的时候，生成相应控件的lua代码。

# 编译环境
Flash Builder4.6

# 使用方法
1、把FairyGUI2Lua.swc文件拷贝到FairyGUI安装目录下的plugins目录  
2、把template下的Lua文件夹拷贝到FairyGUI安装目录下的template目录  
3、打开FairyGUI编辑器，菜单栏打开工具->插件管理，打开界面中点击重新载入按钮  
4、打开FairyGUI编辑器，菜单栏打开文件->项目设置->自定义属性，右边增加1个属性：[gen_lua]-[true]  
  
注意：1、控件无法跨包引用（跨包无法获取对应的控件子控件对象）  

