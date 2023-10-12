# UVM_ISP
demosaic目的：
搭建用于验证ISP中demosaic的UVM仿真环境。
各个文件夹介绍
A01_RTL：RTL 代码
A02_UVM：UVM 代码
DO1_input_img:输入的rggb图像
D02_exp_img: matlab实现的reference model 图像
D03_act_img: UVM仿真输出图像

sim_UVM: 执行仿真的指令。
    make all1 === 编译 + 仿真运行case
    make cov  === 查看覆盖率


项目中的具体内容介绍可以参考：
https://blog.csdn.net/EyRe1?type=blog
ISP图像处理之Demosaic算法 这几篇blog
