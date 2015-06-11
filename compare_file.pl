#######################################################################################
# compare_file.pl                                                                     #
# ISNʵ���� �δ�                                                                      #
# 2014/12/5-2014/12/8                                                                 #
# ˵����                                                                              #
#     �Աȷ��͵����ݺͽ��յ������ļ�                                                  #
#                                                                                     #
#                                                                                     #
#######################################################################################

print "��������ļ�����:";

$file_send = "./output/frame.txt";
$file_receive = <STDIN>;#"./output/frame_receive.txt";

open(SEND,$file_send) or die "���ļ� $file_send ʧ��\n";
open(RECEIVE,$file_receive) or die "���ļ� $file_receive ʧ��\n";

#-------------------------------------------------------------------

print "\n","-" x 10,"��ʼ�Ա�","-" x 10,"\n";


#�Խ����ļ����շ��ͱ�Ž�������
my %send_hash;
my $send_no_str;
my $send_no;
my $row = 0;
#�����ļ�
while($line = <RECEIVE>){
    chomp($line);
    $row++;
    $send_no_str = substr($line,length($line)-16,8);
    $send_hash{$send_no_str} = $row.",".$line;
    #print $row.",".$line,"\n";
}

#����ֵ����
my @keys_sort = sort keys %send_hash;

#��ȡ�����ļ�
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
        #���Ҳ�ͬ�ĵط�
        @x = split '', $line;
        @y = split '', $receive_line;
        $result = join '',
                  map { $x[$_] eq $y[$_] ? "*" : $y[$_] }
                  0 .. $#y;
        print "�����ļ��� $row ��������ļ��� $receive_line_row �в�һ�£����ͱ��$send_no\n";
        print "���ͣ�$line\n";
        print "���գ�$receive_line\n";
        print "���죺$result\n\n"
    }
    else{
        #print "--\n";
    }
}

#-------------------------------------------------------------------
close SEND;
close RECEIVE;

print "\n","-" x 10,"�ԱȽ���","-" x 10,"\n";