#######################################################################################
# main.pl                                                                             #
# ISNʵ���� �δ�                                                                      #
# 2014/12/5-2014/12/6                                                                 #
# ˵����                                                                              #
#      1.������̫��֡                                                                 #
#      2.���������ļ����ֱ���֡�����ļ���֡ͷ�ļ���֡���ļ�                           #
#        ����ļ��ڵ�ǰĿ¼��output�ļ�����                                           #
#      3.����4�ֽ���̫��CRCУ��ֵ(֡��60-1514)                                        #
#      4.CRC32У���㷨ʹ��C++��д������Ŀ¼crc��                                      #
#                                                                                     #
# ���л�����                                                                          #
#      perl/ActivePerl                                                                #
#######################################################################################


=pod

����IP֡ʱ
+------------+---------+-----------+--------------+-------+---------+-----------------+
| ��̫��ͷ�� | IPͷ��  | TCP�˿ں� | �������     | �к�  | CRCУ�� | ��̫��CRC(��ѡ) |
|   14�ֽ�   | 20�ֽ�  |   4�ֽ�   | (64~1518)-50 | 4�ֽ� |  4�ֽ�  |     4�ֽ�       |
+------------+---------+-----------+--------------+-------+---------+-----------------+

ע����(TCP�˿ں�ͷ��~�к�)����CRCУ��ֵ

����ARP֡ʱ
+------------+---------+--------------------------+-------+---------+-----------------+
| ��̫��ͷ�� | ARPͷ�� |        �������          | �к�  | CRCУ�� | ��̫��CRC(��ѡ) |
|   14�ֽ�   | 28�ֽ�  |        (64~1518)-54      | 4�ֽ� |  4�ֽ�  |     4�ֽ�       |
+------------+---------+--------------------------+-------+---------+-----------------+

ע����(ARPͷ��~�к�)����CRCУ��ֵ
    �к�������֡���ļ��е��кţ���0����
    
MAC��ַ��������
    mac(0)   --> mac(0)+1
    mac(0)+1 --> mac(0)+2
    ...
    mac(0)+i --> mac(0)+i+1
    ...
    mac(0)+n --> mac(0)
    
=cut

#�Ƿ�������ģʽ
#����ʱ��debugΪ1
$debug = 0;

#-------------------------------------------------------------
print "\n","*" x 15,"��̫��֡������","*" x 15,"\n\n";

#------------------------��������-----------------------------
$ETHERNET_MAX_LENGTH = 1518; #��̫���֡�ֽ���
$ETHERNET_MIN_LENGTH = 64;   #��̫�����֡�ֽ���
$ETHERNET_CRC_LENGTH = 4;    #��̫��CRC�ֽ���
#-------------------------------------------------------------

#------------------------�����ļ�-----------------------------
$outdir = "./output/";
$frame_file = $outdir."frame.txt";
$frame_length_file = $outdir."frame_length.txt";
$frame_header_file = $outdir."frame_header.txt";

unless (-d $outdir){
    #����ļ��в�����
    mkdir $outdir;
}

open FRAME_FILE,">",$frame_file or die "���ļ�ʧ��";
open FRAME_LENGTH_FILE,">",$frame_length_file or die "���ļ�ʧ��";
open FRAME_HEADER_FILE,">",$frame_header_file or die "���ļ�ʧ��";

#-------------------------------------------------------------

print "�����ļ�����������֡��Ŀ,ֱ�ӻس�����ΪĬ��ֵ10����";
$row_cnt = <STDIN>;
chomp($row_cnt);
if($row_cnt =~ /^$/){
    print "�ļ���������ΪĬ��ֵ10\n";
    $row_cnt = 10;
}
else{
    while(!($row_cnt =~ /\d+/)){
        print "�ļ��������벻�����֣��������룺\n";
        $row_cnt = <STDIN>;
        chomp($row_cnt);
    }
}
print "-" x 20,"\n";

#---------------------֡����������----------------------------
print "ѡ��֡����������(1��2)��\n";
print "ֱ�ӻس�Ĭ��ѡ��1����\n";
print "1. ����\n";
print "2. ���\n";
$frame_length_type = <STDIN>;
chomp($frame_length_type);
if($frame_length_type =~/^$/){
    print "֡��������������ΪĬ������\n";
    $frame_length_type = 1;
}
else{
    while($length_type>2 || $length_type<1){
        print "��������룬ѡ��֡����������(1��2)��\n";
        $frame_length_type = <STDIN>;
    }
}
print "-" x 20,"\n";

#-------------------------------------------------------------
my $base_frame_length;
my $interval;
if($frame_length_type==1){
    print "\nѡ����֡���Զ�����...\n";
    print "ֱ�ӻس�����ΪĬ��ֵ64��\n";
    print "����֡����ʼֵ(64-1518)��";
    $base_frame_length = <STDIN>;
    chomp($base_frame_length);
    if($base_frame_length =~//){
        print "����֡����ʼֵ����ΪĬ��ֵ64\n";
        $base_frame_length = 64;
    }
    else{
        while($base_frame_length>1518 || $base_frame_length<64){
            print "֡�����ڷ�Χ�ڣ�����������ʼֵ(64-1518)��\n";
            $base_frame_length = <STDIN>;
            chomp($base_frame_length);
        }
    }
    
    #-----------------------------------------------
    print "�������Ӽ��(ֱ�ӻس�ѡ��Ĭ��ֵ1)��\n";
    $interval = <STDIN>;
    chomp($interval);
    if($interval =~//){
        print "���Ӽ������ΪΪĬ��ֵ64\n";
        $interval = 1;
    }
    else{
        while(!($interval =~ /\d+/)){
            print "��������������Ӽ����\n";
            $interval = <STDIN>;
            chomp($interval);
        }
    }
}
print "\n","-" x 20,"\n";

#--------------------MAC��ַ��������---------------------------
print "MAC��ַ�������ԣ�����\n";
print "������ʼMAC��ַ(Ĭ��001122334455,ֱ�ӻس�ѡ��Ĭ��)��";
$base_mac = <STDIN>;
chomp($base_mac);
if($base_mac =~//){
    print "��ʼMAC��ַ����ΪĬ��001122334455\n";
    $base_mac = "001122334455";
}
else{
    #������ʽ�ж������ʽ�Ƿ���ȷ
    while(!($base_mac =~ /[0-9a-fA-F]{12}/)){
        print "��������룬����������ʼMAC��ַ(��001122334455)��\n";
        $base_mac = <STDIN>;
        chomp($base_mac);
    }
}
print "\n","-" x 20,"\n";

#--------------------����������------------------------------
print "������ݲ������ԣ�(1��2,ֱ�ӻس�ѡ��Ĭ��2α���)��\n";
print "1. �̶�\n";
print "2. α���\n";
$fill_data_type = <STDIN>;
chomp($fill_data_type);
if($fill_data_type =~ //){
    $fill_data_type = 2;
}
else{
    while($fill_data_type>3){
        print "��������룬ѡ��������ݲ�������(1��2)��\n";
        $fill_data_type = <STDIN>;
        chomp($fill_data_type);
    }
}
print "\n","-" x 20,"\n";

my $fixed_fill_data;
if($fill_data_type==1){
    print "\nѡ���˹̶��������...\n";
    print "����������ݣ�16λ,��:aabb����";
    $fixed_fill_data = <STDIN>;
    chomp($fixed_fill_data);
}

#########################################################################
#��̫��ͷ��
my $ethernet_header;
#��̫����֡��
my $frame_length;

srand;
for($i=0;$i<$row_cnt;$i++){

    if($frame_length_type==1){
        #֡������
        $frame_length = $base_frame_length + $interval*$i;
        if($frame_length>$ETHERNET_MAX_LENGTH){
            $frame_length = $ETHERNET_MAX_LENGTH;
        }
    }
    else{
        #����64-1518�������
        $frame_length = $ETHERNET_MIN_LENGTH + int(rand($ETHERNET_MAX_LENGTH-$ETHERNET_MIN_LENGTH));
    }

    #Ŀ��MAC��ַ���趨Ϊ��һ�����ݵ�ԴMAC��
    my $mac_dst = dec2hexStr(hex($base_mac)+$i+1,12);
    #ԴMAC��ַ (����)
    my $mac_src = dec2hexStr(hex($base_mac)+$i,12);
    if($debug==1){
        print("*********************mac_src is $mac_src\n",);
    }
    if($i==$row_cnt-1){
        #���һ�����ݣ�Ŀ��MAC��Ϊ��һ������MAC
        $mac_dst = dec2hexStr(hex($base_mac),12); 
    }
    
    #�������֡����
    if(0==int(rand(100))%2)
    {
        print $i,"----IP����֡----\n";
        
        #IP֡ TCP/UDP
        $ethernet_type = "0800";
        $ethernet_header = $mac_dst.$mac_src.$ethernet_type;
        
        #------------------------------------------------------------------------------------
        
        #��IPͷ�����غɸ�ʽ��
        #�汾�ţ�0100��ʾIPV4��0110��ʾIPV6.
        #[4λ�汾��|4λ�ײ�����|8λ��������|16λ���ֽ���      ]
        #[16λ��ʾ                         |3λ��־|13λƬƫ��]
        #[8λ����ʱ��          |8λЭ��    |16λ�ײ�У���    ]
        #[32λԴIP��ַ                                        ]
        #[32λĿ��IP��ַ                                      ]
        #[16λԴ�˿ں�                     |16λĿ�Ķ˿ں�    ]###��ʼTCPЭ��
        #[���ݺ����]
        #[4�ֽ�����CRCУ��ֵ]
        
        #---------------------------IP�̶�ͷ��20�ֽ�-----------------------------------------
        #Ĭ��ipv4��4λ��
        $ip_version = dec2hexStr(0b0100,1);
        #�ײ����ȣ�4λ����4�ֽ�Ϊ��λ��Ĭ��Ϊ5��
        $head_length = dec2hexStr(0b0101,1);
        #�������ͣ�8λ�����ã�
        $service_type = dec2hexStr(0b00000000,2);
        #�ײ����������ֽ��� = ֡��-18��16λ��
        $total_bytes = dec2hexStr($frame_length-18,4);
        #��ʾ
        $identification = dec2hexStr(0b0000_0000_0000_0000,4);
        #��־������Ƭ��,ƫ��Ϊ0
        $flag_offset = dec2hexStr(0b010_0_0000_0000_0000,4);
        #����ʱ�䣨128��
        $ttl = dec2hexStr(128,2);
        #8λЭ�飨Ĭ��TCP��
        $protocol = dec2hexStr(0x06,2);
        #�ײ�У��ͣ������㣩
        $head_checksum = dec2hexStr(0x0000,4);
        #IP��ַ192.168.0.1/192.168.0.2
        $src_ip = dec2hexStr(192,2).dec2hexStr(168,2).dec2hexStr(0,2).dec2hexStr(1,2);
        #print $src_ip,"---Դ\n";
        $dst_ip = dec2hexStr(192,2).dec2hexStr(168,2).dec2hexStr(0,2).dec2hexStr(2,2);
        #print $dst_ip,"---Ŀ��\n";
        #------------------------------------------------------------------------------------
        
        #---------------------------TCPЭ��ͷ��----------------------------------------------
        $src_port = dec2hexStr(100,4);#Դ�˿�
        $dst_port = dec2hexStr(80,4); #Ŀ�Ķ˿�

        #------------------------------------------------------------------------------------
        #TCPЭ������ͷ��������
        my $payload;
        my $data_size = int(($frame_length - 50)/2);#2�ֽڵ�����
        if($fill_data_type == 1){
            #�̶����
            for(1..$data_size){
                $payload .= $fixed_fill_data;
            }
        }
        else{
            #α������
            $last_data = 0xABCD;
            $payload = dec2hexStr($last_data,4);
            for(2..$data_size){
                $current_data = (~((($last_data & 0b0001_0000_0000_0000)<<3)^(($last_data & 0b0000_0000_0000_1000)<<12)^(($last_data & 0b0000_0000_0000_0010)<<14)^(($last_data & 0b0000_0000_0000_0001)<<15)))&(0b1000_0000_0000_0000)|(($last_data & 0b1111_1111_1111_1110)>>1);
                $payload .= dec2hexStr($current_data,4);
                #print dec2hexStr($current_data,4),"\n";
                $last_data = $current_data;
            }
            if(($frame_length - 50)%2==1){
                #��ʣ����8bit
                $current_data = (~((($last_data & 0b0001_0000_0000_0000)<<3)^(($last_data & 0b0000_0000_0000_1000)<<12)^(($last_data & 0b0000_0000_0000_0010)<<14)^(($last_data & 0b0000_0000_0000_0001)<<15)))&(0b1000_0000_0000_0000)|(($last_data & 0b1111_1111_1111_1110)>>1);
                $payload .= substr(dec2hexStr($current_data,4),2,2);#ȡ��8λ
                #print substr(dec2hexStr($current_data,4),2,2),"\n";
            }
        }
        
        #------------------------------------------------------------------------------------
        
        #����кţ�32λ��
        $current_row = dec2hexStr($i,8);
        
        #IPЭ��ͷ��+����
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
        
        #���CRCУ��ֵ
        $crc = getCRC32($ip_protocal_data);        
        
        print FRAME_FILE $ethernet_header.$ip_protocal_all.$crc,"\n";
        print FRAME_HEADER_FILE "$ethernet_header,$ip_protocal_head,$current_row,$crc\n";
    }
    else
    {
        print $i,"----ARP����֡----\n";
        
        #------------------------------------------------------------------------------------
        
        $ethernet_type = "0806";
        $ethernet_header = $mac_dst.$mac_src.$ethernet_type;
        
        #------------------------------------------------------------------------------------
        #ARP֡ͷ��
        #[2BӲ������|2BЭ������|1BӲ����ַ����|1BЭ���ַ����|2BOP|6B������Ӳ����ַ
        # |4B������IP|6BĿ��Ӳ����ַ|4BĿ��IP��ַ]
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
        my $data_size = int(($frame_length - 54)/2);#2�ֽڵ�����
        if($fill_data_type == 1){
            #�̶����
            for(1..$data_size){
                $payload .= $fixed_fill_data;
            }
        }
        else{
            #α������
            $last_data = 0xABCD;
            $payload = dec2hexStr($last_data,4);
            for(2..$data_size){
                $current_data = (~((($last_data & 0b0001_0000_0000_0000)<<3)^(($last_data & 0b0000_0000_0000_1000)<<12)^(($last_data & 0b0000_0000_0000_0010)<<14)^(($last_data & 0b0000_0000_0000_0001)<<15)))&(0b1000_0000_0000_0000)|(($last_data & 0b1111_1111_1111_1110)>>1);
                $payload .= dec2hexStr($current_data,4);
                $last_data = $current_data;
            }
            if(($frame_length - 54)%2==1){
                #��ʣ����8bit
                $current_data = (~((($last_data & 0b0001_0000_0000_0000)<<3)^(($last_data & 0b0000_0000_0000_1000)<<12)^(($last_data & 0b0000_0000_0000_0010)<<14)^(($last_data & 0b0000_0000_0000_0001)<<15)))&(0b1000_0000_0000_0000)|(($last_data & 0b1111_1111_1111_1110)>>1);
                $payload .= substr(dec2hexStr($current_data,4),2,2);#ȡ��8λ
            }
        }
        
        #------------------------------------------------------------------------------------
        
        #����кţ�32λ��
        $current_row = dec2hexStr($i,8);
        
        #------------------------------------------------------------------------------------
        #ARPЭ��ͷ��+����
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
        
        #���CRCУ��ֵ
        $crc = getCRC32($arp_protocal_all);
        
        print FRAME_FILE $ethernet_header.$arp_protocal_all.$crc,"\n";
        print FRAME_HEADER_FILE "$ethernet_header,$arp_protocal_head,$current_row,$crc\n";
    }
    
    #д���ļ�
    print FRAME_LENGTH_FILE ($frame_length-$ETHERNET_CRC_LENGTH)."\n";
}

#########################################################################

close FRAME_FILE;
close FRAME_LENGTH_FILE;
close FRAME_HEADER_FILE;
print "\n--------------���н���------------\n";

##############################�Ӻ���######################################

#ʮ����ת16����
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

#����CRCУ��ֵ
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
