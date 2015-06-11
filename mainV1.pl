#######################################################################################
# main.pl                                                                             #
# ISN实验室 段聪                                                                      #
# 2014/12/5-2014/12/6                                                                 #
# 说明：                                                                              #
#      1.生成以太网帧                                                                 #
#      2.生成三个文件，分别是帧数据文件，帧头文件，帧长文件                           #
#        输出文件在当前目录的output文件夹中                                           #
#      3.忽略4字节以太网CRC校验值(帧长60-1514)                                        #
#      4.CRC32校验算法使用C++编写，在子目录crc中                                      #
#                                                                                     #
# 运行环境：                                                                          #
#      perl/ActivePerl                                                                #
#######################################################################################


=pod

承载IP帧时
+------------+---------+-----------+--------------+-------+---------+-----------------+
| 以太网头部 | IP头部  | TCP端口号 | 数据填充     | 行号  | CRC校验 | 以太网CRC(不选) |
|   14字节   | 20字节  |   4字节   | (64~1518)-50 | 4字节 |  4字节  |     4字节       |
+------------+---------+-----------+--------------+-------+---------+-----------------+

注：对(TCP端口号头部~行号)计算CRC校验值

承载ARP帧时
+------------+---------+--------------------------+-------+---------+-----------------+
| 以太网头部 | ARP头部 |        数据填充          | 行号  | CRC校验 | 以太网CRC(不选) |
|   14字节   | 28字节  |        (64~1518)-54      | 4字节 |  4字节  |     4字节       |
+------------+---------+--------------------------+-------+---------+-----------------+

注：对(ARP头部~行号)计算CRC校验值
    行号是数据帧在文件中的行号，从0计数
    
MAC地址产生策略
    mac(0)   --> mac(0)+1
    mac(0)+1 --> mac(0)+2
    ...
    mac(0)+i --> mac(0)+i+1
    ...
    mac(0)+n --> mac(0)
    
=cut

#是否开启调试模式
#开启时候debug为1
$debug = 0;

#-------------------------------------------------------------
print "\n","*" x 15,"以太网帧生成器","*" x 15,"\n\n";

#------------------------常量定义-----------------------------
$ETHERNET_MAX_LENGTH = 1518; #以太网最长帧字节数
$ETHERNET_MIN_LENGTH = 64;   #以太网最短帧字节数
$ETHERNET_CRC_LENGTH = 4;    #以太网CRC字节数
#-------------------------------------------------------------

#------------------------创建文件-----------------------------
$outdir = "./output/";
$frame_file = $outdir."frame.txt";
$frame_length_file = $outdir."frame_length.txt";
$frame_header_file = $outdir."frame_header.txt";

unless (-d $outdir){
    #输出文件夹不存在
    mkdir $outdir;
}

open FRAME_FILE,">",$frame_file or die "打开文件失败";
open FRAME_LENGTH_FILE,">",$frame_length_file or die "打开文件失败";
open FRAME_HEADER_FILE,">",$frame_header_file or die "打开文件失败";

#-------------------------------------------------------------

print "输入文件行数（产生帧数目,直接回车设置为默认值10）：";
$row_cnt = <STDIN>;
chomp($row_cnt);
if($row_cnt =~ /^$/){
    print "文件行数设置为默认值10\n";
    $row_cnt = 10;
}
else{
    while(!($row_cnt =~ /\d+/)){
        print "文件行数输入不是数字，重新输入：\n";
        $row_cnt = <STDIN>;
        chomp($row_cnt);
    }
}
print "-" x 20,"\n";

#---------------------帧长产生策略----------------------------
print "选择帧长产生策略(1或2)：\n";
print "直接回车默认选择1自增\n";
print "1. 自增\n";
print "2. 随机\n";
$frame_length_type = <STDIN>;
chomp($frame_length_type);
if($frame_length_type =~/^$/){
    print "帧长产生策略设置为默认自增\n";
    $frame_length_type = 1;
}
else{
    while($length_type>2 || $length_type<1){
        print "错误的输入，选择帧长产生策略(1或2)：\n";
        $frame_length_type = <STDIN>;
    }
}
print "-" x 20,"\n";

#-------------------------------------------------------------
my $base_frame_length;
my $interval;
if($frame_length_type==1){
    print "\n选择了帧长自动增加...\n";
    print "直接回车设置为默认值64：\n";
    print "输入帧长起始值(64-1518)：";
    $base_frame_length = <STDIN>;
    chomp($base_frame_length);
    if($base_frame_length =~//){
        print "输入帧长起始值设置为默认值64\n";
        $base_frame_length = 64;
    }
    else{
        while($base_frame_length>1518 || $base_frame_length<64){
            print "帧长不在范围内，重新输入起始值(64-1518)：\n";
            $base_frame_length = <STDIN>;
            chomp($base_frame_length);
        }
    }
    
    #-----------------------------------------------
    print "输入增加间隔(直接回车选择默认值1)：\n";
    $interval = <STDIN>;
    chomp($interval);
    if($interval =~//){
        print "增加间隔设置为为默认值64\n";
        $interval = 1;
    }
    else{
        while(!($interval =~ /\d+/)){
            print "输入错误，输入增加间隔：\n";
            $interval = <STDIN>;
            chomp($interval);
        }
    }
}
print "\n","-" x 20,"\n";

#--------------------MAC地址产生策略---------------------------
print "MAC地址产生策略：自增\n";
print "输入起始MAC地址(默认001122334455,直接回车选择默认)：";
$base_mac = <STDIN>;
chomp($base_mac);
if($base_mac =~//){
    print "起始MAC地址设置为默认001122334455\n";
    $base_mac = "001122334455";
}
else{
    #正则表达式判断输入格式是否正确
    while(!($base_mac =~ /[0-9a-fA-F]{12}/)){
        print "错误的输入，重新输入起始MAC地址(如001122334455)：\n";
        $base_mac = <STDIN>;
        chomp($base_mac);
    }
}
print "\n","-" x 20,"\n";

#--------------------数据填充策略------------------------------
print "填充数据产生策略：(1或2,直接回车选择默认2伪随机)：\n";
print "1. 固定\n";
print "2. 伪随机\n";
$fill_data_type = <STDIN>;
chomp($fill_data_type);
if($fill_data_type =~ //){
    $fill_data_type = 2;
}
else{
    while($fill_data_type>3){
        print "错误的输入，选择填充数据产生策略(1或2)：\n";
        $fill_data_type = <STDIN>;
        chomp($fill_data_type);
    }
}
print "\n","-" x 20,"\n";

my $fixed_fill_data;
if($fill_data_type==1){
    print "\n选择了固定数据填充...\n";
    print "输入填充数据（16位,例:aabb）：";
    $fixed_fill_data = <STDIN>;
    chomp($fixed_fill_data);
}

#########################################################################
#以太网头部
my $ethernet_header;
#以太网总帧长
my $frame_length;

srand;
for($i=0;$i<$row_cnt;$i++){

    if($frame_length_type==1){
        #帧长自增
        $frame_length = $base_frame_length + $interval*$i;
        if($frame_length>$ETHERNET_MAX_LENGTH){
            $frame_length = $ETHERNET_MAX_LENGTH;
        }
    }
    else{
        #产生64-1518的随机数
        $frame_length = $ETHERNET_MIN_LENGTH + int(rand($ETHERNET_MAX_LENGTH-$ETHERNET_MIN_LENGTH));
    }

    #目的MAC地址（设定为下一条数据的源MAC）
    my $mac_dst = dec2hexStr(hex($base_mac)+$i+1,12);
    #源MAC地址 (自增)
    my $mac_src = dec2hexStr(hex($base_mac)+$i,12);
    if($debug==1){
        print("*********************mac_src is $mac_src\n",);
    }
    if($i==$row_cnt-1){
        #最后一条数据，目的MAC变为第一条数据MAC
        $mac_dst = dec2hexStr(hex($base_mac),12); 
    }
    
    #随机产生帧类型
    if(0==int(rand(100))%2)
    {
        print $i,"----IP数据帧----\n";
        
        #IP帧 TCP/UDP
        $ethernet_type = "0800";
        $ethernet_header = $mac_dst.$mac_src.$ethernet_type;
        
        #------------------------------------------------------------------------------------
        
        #【IP头部与载荷格式】
        #版本号：0100表示IPV4，0110表示IPV6.
        #[4位版本号|4位首部长度|8位服务类型|16位总字节数      ]
        #[16位标示                         |3位标志|13位片偏移]
        #[8位生存时间          |8位协议    |16位首部校验和    ]
        #[32位源IP地址                                        ]
        #[32位目的IP地址                                      ]
        #[16位源端口号                     |16位目的端口号    ]###开始TCP协议
        #[数据和填充]
        #[4字节数据CRC校验值]
        
        #---------------------------IP固定头部20字节-----------------------------------------
        #默认ipv4（4位）
        $ip_version = dec2hexStr(0b0100,1);
        #首部长度（4位，以4字节为单位，默认为5）
        $head_length = dec2hexStr(0b0101,1);
        #服务类型（8位，不用）
        $service_type = dec2hexStr(0b00000000,2);
        #首部和数据总字节数 = 帧长-18（16位）
        $total_bytes = dec2hexStr($frame_length-18,4);
        #标示
        $identification = dec2hexStr(0b0000_0000_0000_0000,4);
        #标志（不分片）,偏移为0
        $flag_offset = dec2hexStr(0b010_0_0000_0000_0000,4);
        #生存时间（128）
        $ttl = dec2hexStr(128,2);
        #8位协议（默认TCP）
        $protocol = dec2hexStr(0x06,2);
        #首部校验和（不计算）
        $head_checksum = dec2hexStr(0x0000,4);
        #IP地址192.168.0.1/192.168.0.2
        $src_ip = dec2hexStr(192,2).dec2hexStr(168,2).dec2hexStr(0,2).dec2hexStr(1,2);
        #print $src_ip,"---源\n";
        $dst_ip = dec2hexStr(192,2).dec2hexStr(168,2).dec2hexStr(0,2).dec2hexStr(2,2);
        #print $dst_ip,"---目的\n";
        #------------------------------------------------------------------------------------
        
        #---------------------------TCP协议头部----------------------------------------------
        $src_port = dec2hexStr(100,4);#源端口
        $dst_port = dec2hexStr(80,4); #目的端口

        #------------------------------------------------------------------------------------
        #TCP协议其他头部和数据
        my $payload;
        my $data_size = int(($frame_length - 50)/2);#2字节的总数
        if($fill_data_type == 1){
            #固定填充
            for(1..$data_size){
                $payload .= $fixed_fill_data;
            }
        }
        else{
            #伪随机填充
            $last_data = 0xABCD;
            $payload = dec2hexStr($last_data,4);
            for(2..$data_size){
                $current_data = (~((($last_data & 0b0001_0000_0000_0000)<<3)^(($last_data & 0b0000_0000_0000_1000)<<12)^(($last_data & 0b0000_0000_0000_0010)<<14)^(($last_data & 0b0000_0000_0000_0001)<<15)))&(0b1000_0000_0000_0000)|(($last_data & 0b1111_1111_1111_1110)>>1);
                $payload .= dec2hexStr($current_data,4);
                #print dec2hexStr($current_data,4),"\n";
                $last_data = $current_data;
            }
            if(($frame_length - 50)%2==1){
                #还剩单独8bit
                $current_data = (~((($last_data & 0b0001_0000_0000_0000)<<3)^(($last_data & 0b0000_0000_0000_1000)<<12)^(($last_data & 0b0000_0000_0000_0010)<<14)^(($last_data & 0b0000_0000_0000_0001)<<15)))&(0b1000_0000_0000_0000)|(($last_data & 0b1111_1111_1111_1110)>>1);
                $payload .= substr(dec2hexStr($current_data,4),2,2);#取低8位
                #print substr(dec2hexStr($current_data,4),2,2),"\n";
            }
        }
        
        #------------------------------------------------------------------------------------
        
        #添加行号（32位）
        $current_row = dec2hexStr($i,8);
        
        #IP协议头部+数据
        $ip_protocal_head =  $ip_version
                            .$head_length
                            .$service_type
                            .$total_bytes
                            .$identification
                            .$flag_offset
                            .$ttl
                            .$protocol
                            .$head_checksum
                            .$src_ip
                            .$dst_ip;
                            
        $ip_protocal_data =  $src_port
                            .$dst_port
                            .$payload
                            .$current_row;
                            
        $ip_protocal_all =  $ip_protocal_head.$ip_protocal_data;
        
        #添加CRC校验值
        $crc = getCRC32($ip_protocal_data);        
        
        print FRAME_FILE $ethernet_header.$ip_protocal_all.$crc,"\n";
        print FRAME_HEADER_FILE "$ethernet_header,$ip_protocal_head,$current_row,$crc\n";
    }
    else
    {
        print $i,"----ARP数据帧----\n";
        
        #------------------------------------------------------------------------------------
        
        $ethernet_type = "0806";
        $ethernet_header = $mac_dst.$mac_src.$ethernet_type;
        
        #------------------------------------------------------------------------------------
        #ARP帧头部
        #[2B硬件类型|2B协议类型|1B硬件地址长度|1B协议地址长度|2BOP|6B发送者硬件地址
        # |4B发送者IP|6B目标硬件地址|4B目标IP地址]
        my $hardware_type = dec2hexStr(0x0001,4);
        my $protocal_type = dec2hexStr(0x0800,4);
        my $hardware_size = dec2hexStr(0x06,2);
        my $protocal_size = dec2hexStr(0x04,2);
        my $op = dec2hexStr(0x0001,4);
        my $sender_mac = $mac_src;
        my $sender_ip = dec2hexStr(192,2).dec2hexStr(168,2).dec2hexStr(0,2).dec2hexStr(1,2);
        my $target_mac = dec2hexStr(0x000000000000,12);
        my $target_ip = dec2hexStr(192,2).dec2hexStr(168,2).dec2hexStr(0,2).dec2hexStr(2,2);
        
        if($debug==1){
             print "length of hardware_type $hardware_type is ".length($hardware_type)."\n";
             print "length of protocal_type $protocal_type is ".length($protocal_type)."\n";
             print "length of hardware_size $hardware_size is ".length($hardware_size)."\n";
             print "length of protocal_size $protocal_size is ".length($protocal_size)."\n";
             print "length of op $op is ".length($op)."\n";
             print "length of sender_mac $sender_mac is ".length($sender_mac)."\n";
             print "length of sender_ip  $sender_ip is ".length($sender_ip)."\n";
             print "length of target_mac $target_mac is ".length($target_mac)."\n";
             print "length of target_ip  $target_ip is ".length($target_ip)."\n";
        }
       
        #------------------------------------------------------------------------------------
        my $payload;
        my $data_size = int(($frame_length - 54)/2);#2字节的总数
        if($fill_data_type == 1){
            #固定填充
            for(1..$data_size){
                $payload .= $fixed_fill_data;
            }
        }
        else{
            #伪随机填充
            $last_data = 0xABCD;
            $payload = dec2hexStr($last_data,4);
            for(2..$data_size){
                $current_data = (~((($last_data & 0b0001_0000_0000_0000)<<3)^(($last_data & 0b0000_0000_0000_1000)<<12)^(($last_data & 0b0000_0000_0000_0010)<<14)^(($last_data & 0b0000_0000_0000_0001)<<15)))&(0b1000_0000_0000_0000)|(($last_data & 0b1111_1111_1111_1110)>>1);
                $payload .= dec2hexStr($current_data,4);
                $last_data = $current_data;
            }
            if(($frame_length - 54)%2==1){
                #还剩单独8bit
                $current_data = (~((($last_data & 0b0001_0000_0000_0000)<<3)^(($last_data & 0b0000_0000_0000_1000)<<12)^(($last_data & 0b0000_0000_0000_0010)<<14)^(($last_data & 0b0000_0000_0000_0001)<<15)))&(0b1000_0000_0000_0000)|(($last_data & 0b1111_1111_1111_1110)>>1);
                $payload .= substr(dec2hexStr($current_data,4),2,2);#取低8位
            }
        }
        
        #------------------------------------------------------------------------------------
        
        #添加行号（32位）
        $current_row = dec2hexStr($i,8);
        
        #------------------------------------------------------------------------------------
        #ARP协议头部+数据
        $arp_protocal_head =  $hardware_type
                             .$protocal_type
                             .$hardware_size
                             .$protocal_size
                             .$op
                             .$sender_mac
                             .$sender_ip
                             .$target_mac
                             .$target_ip;
        
        $arp_protocal_data =  $payload
                             .$current_row; 
                             
        $arp_protocal_all =  $arp_protocal_head.$arp_protocal_data;
        if($debug==1){
            print "length of arp_protocal_head is ".length($arp_protocal_head)."\n";
        }
        
        #添加CRC校验值
        $crc = getCRC32($arp_protocal_all);
        
        print FRAME_FILE $ethernet_header.$arp_protocal_all.$crc,"\n";
        print FRAME_HEADER_FILE "$ethernet_header,$arp_protocal_head,$current_row,$crc\n";
    }
    
    #写入文件
    print FRAME_LENGTH_FILE ($frame_length-$ETHERNET_CRC_LENGTH)."\n";
}

#########################################################################

close FRAME_FILE;
close FRAME_LENGTH_FILE;
close FRAME_HEADER_FILE;
print "\n--------------运行结束------------\n";

##############################子函数######################################

#十进制转16进制
sub dec2hexStr{
    my $fix_wdth = 0;
    if(@_ > 1)
    {
        $fix_wdth = 1;
    }
    my $data = shift @_;
    my $data16 = sprintf("%x", $data); 
    my $width = shift @_;
    if($fix_wdth==1)
    {
        if(length($data16)<$width)
        {
            $data16 = ("0" x ($width-length($data16))).$data16;
        }
    }
    return $data16;
}

#计算CRC校验值
sub getCRC32{
    $data = shift @_;
    $str = readpipe("./crc/exe/crc.exe $data");
    $str = substr($str,4,8);
    $str1 = substr($str,0,2);
    $str2 = substr($str,2,2);
    $str3 = substr($str,4,2);
    $str4 = substr($str,6,2);
    $crc = $str4.$str3.$str2.$str1;
    return $crc;
}
