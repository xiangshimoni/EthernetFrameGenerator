#######################################################################################
# compare_file.pl                                                                     #
# ISN实验室 段聪                                                                      #
# 2014/12/5-2014/12/8                                                                 #
# 说明：                                                                              #
#     对比发送的数据和接收的数据文件                                                  #
#                                                                                     #
#                                                                                     #
#######################################################################################

print "输入接收文件名称:";

$file_send = "./output/frame.txt";
$file_receive = <STDIN>;#"./output/frame_receive.txt";

open(SEND,$file_send) or die "打开文件 $file_send 失败\n";
open(RECEIVE,$file_receive) or die "打开文件 $file_receive 失败\n";

#-------------------------------------------------------------------

print "\n","-" x 10,"开始对比","-" x 10,"\n";


#对接收文件按照发送编号进行排序
my %send_hash;
my $send_no_str;
my $send_no;
my $row = 0;
#接收文件
while($line = <RECEIVE>){
    chomp($line);
    $row++;
    $send_no_str = substr($line,length($line)-16,8);
    $send_hash{$send_no_str} = $row.",".$line;
    #print $row.",".$line,"\n";
}

#按键值排序
my @keys_sort = sort keys %send_hash;

#读取发送文件
print "\n";
$row = 0;
my $receive_line;
my @x,@y;
while($line = <SEND>){
    chomp($line);
    $row++;
    
    $send_no_str = substr($line,length($line)-16,8);
    $receive_all = $send_hash{$send_no_str};
    @receive_line_with_row = split ',',$receive_all;
    $receive_line_row = $receive_line_with_row[0];
    $receive_line = $receive_line_with_row[1];
    
    if($line ne $receive_line){
        #查找不同的地方
        @x = split '', $line;
        @y = split '', $receive_line;
        $result = join '',
                  map { $x[$_] eq $y[$_] ? "*" : $y[$_] }
                  0 .. $#y;
        print "发送文件第 $row 行与接收文件第 $receive_line_row 行不一致，发送编号$send_no\n";
        print "发送：$line\n";
        print "接收：$receive_line\n";
        print "差异：$result\n\n"
    }
    else{
        #print "--\n";
    }
}

#-------------------------------------------------------------------
close SEND;
close RECEIVE;

print "\n","-" x 10,"对比结束","-" x 10,"\n";