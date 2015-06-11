# EthernetFrameGenerator
A Perl script for generate Ethernet frame


 main.pl                                                                             
 ISN实验室 段聪                                                                      
 2014/12/5-2014/12/8                                                                 
 说明：                                                                              
      1.生成以太网帧                                                                 
      2.生成三个文件，分别是帧数据文件，帧头文件，帧长文件                           
        输出文件在当前目录的output文件夹中                                           
      3.忽略4字节以太网CRC校验值(帧长60-1514)                                        
      4.CRC32校验算法使用C++编写，在子目录crc中                                      
                                                                                     
 运行环境：                                                                          
      perl/ActivePerl                                                                

 LOG                                                                                 
 V2:                                                                                 
1、(已解决)可以输入设备数n，每个设备都有一个MAC地址和IP地址                          
2、(已解决)ARP帧发送可控（开关），发送的ARP帧位设备的映射关系，                      
            暂定为只发送n个ARP，首先ARP帧                                            
3、(已解决)修改默认值问题                                                            
4、(已解决)生成按字节反序的数据文件 (file_reverse_bytes.pl)                          
                                                                                     
                                                                                     
