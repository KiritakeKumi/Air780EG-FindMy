# Air780EG-FindMy

### 简介

本项目基于

https://gitee.com/bg4uvr/LTE-Tracker

https://gitee.com/ixinme/aprs4g

在此的基础上只保留了Traccar平台的上报能力

### 前言

近日和可爱满满讨论了做一个记录自己足迹的记录器，原方案为移远的BG95模块，后来咕咕，最近看到了合宙的Air780EG模块，然后看到了aprs4g这个项目，于是进行了一些刀法精湛的切割，就有了本项目


### 如何使用

1.下载本项目

2.修改 cfg.lua 里面的 Traccar 服务器地址（TRACCAR_HOST）你需要自己用服务器搭建一个

3.下载 luatools 在合宙官网

4.在 luatools 里面下载 Air780EG 的底包 然后在项目管理中将本项目 code 部分全部导入

5.点击下载底层和脚本 刷入即可

### 后续

目前修改十分初级，还有大量aprs4g无用代码未被删除，后续将会精简
