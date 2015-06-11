#######################################################################################
# file_reverse_bytes.pl                                                               #
# ISN实验室 段聪                                                                      #
# 2014/12/5-2014/12/8                                                                 #
# 说明：                                                                              #
#     对main.pl生成的帧数据文件frame.txt按字节进行反序                                #
#                                                                                     #
#                                                                                     #
#######################################################################################

$input_file = "./output/frame.txt";
$output_file = substr($input_file,0,length($input_file)-4)."_reverse.txt";

open(INPUT_FILE,"<",$input_file) or die "打开文件 $input_file 失败\n";
open(OUTPUT_FILE,">",$output_file) or die "打开文件 $output_file 失败\n";

print "\n","*"x 30,"\n\n";
print "\n----开始反序处理----\n\n";
$cnt = 0;

while($line = <INPUT_FILE>){
    $cnt++;
    print "正在处理第 $cnt 行...\n";
    chomp($line);
    #遍历每一行进行处理
    print OUTPUT_FILE reverse_line($line)."\n";
}

close INPUT_FILE;
close OUTPUT_FILE;

print "\n----处理结束----\n";
print "----输出文件为 $output_file\n\n";

sub reverse_line{
    $str = shift @_;
    $str_reverse = reverse $str;
    my $str_result;
    for($i=0;$i<length($str)-1;$i+=2){
        $str_result.= reverse substr($str_reverse,$i,2);
    }
    return $str_result;
}