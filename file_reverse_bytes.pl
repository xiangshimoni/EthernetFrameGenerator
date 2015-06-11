#######################################################################################
# file_reverse_bytes.pl                                                               #
# ISNʵ���� �δ�                                                                      #
# 2014/12/5-2014/12/8                                                                 #
# ˵����                                                                              #
#     ��main.pl���ɵ�֡�����ļ�frame.txt���ֽڽ��з���                                #
#                                                                                     #
#                                                                                     #
#######################################################################################

$input_file = "./output/frame.txt";
$output_file = substr($input_file,0,length($input_file)-4)."_reverse.txt";

open(INPUT_FILE,"<",$input_file) or die "���ļ� $input_file ʧ��\n";
open(OUTPUT_FILE,">",$output_file) or die "���ļ� $output_file ʧ��\n";

print "\n","*"x 30,"\n\n";
print "\n----��ʼ������----\n\n";
$cnt = 0;

while($line = <INPUT_FILE>){
    $cnt++;
    print "���ڴ���� $cnt ��...\n";
    chomp($line);
    #����ÿһ�н��д���
    print OUTPUT_FILE reverse_line($line)."\n";
}

close INPUT_FILE;
close OUTPUT_FILE;

print "\n----�������----\n";
print "----����ļ�Ϊ $output_file\n\n";

sub reverse_line{
    $str = shift @_;
    $str_reverse = reverse $str;
    my $str_result;
    for($i=0;$i<length($str)-1;$i+=2){
        $str_result.= reverse substr($str_reverse,$i,2);
    }
    return $str_result;
}