=pod
$data = "FFFFFFFFFFFF010101010101ffffFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

$str = readpipe("./crc/crc.exe $data");
$str = substr($str,4,8);
$str1 = substr($str,0,2);
$str2 = substr($str,2,2);
$str3 = substr($str,4,2);
$str4 = substr($str,6,2);
$crc = $str4.$str3.$str2.$str1;


printf("%014b\n",0b0010);
$val = sprintf("%b",0b0010);
#$val = "11010001";
$val = reverse $val;
$dec = ord(pack('B8',$val));
print $dec;


$last_data = 0xABCD;
printf("%16b\n",$last_data);
$current_data = (~((($last_data & 0b0001_0000_0000_0000)<<3) #第3位
                ^(($last_data & 0b0000_0000_0000_1000)<<12)  #第12位
                ^(($last_data & 0b0000_0000_0000_0010)<<14)  #第14位
                ^(($last_data & 0b0000_0000_0000_0001)<<15)))#第15位
                |(($last_data & 0b1111_1111_1111_1110)>>1);

printf("%016b\n",($last_data & 0b0001_0000_0000_0000)<<3);
printf("%016b\n",($last_data & 0b0000_0000_0000_1000)<<12);
printf("%016b\n",($last_data & 0b0000_0000_0000_0010)<<14);
printf("%016b\n\n",($last_data & 0b0000_0000_0000_0001)<<15);

printf("%016b\n\n",(~((($last_data & 0b0001_0000_0000_0000)<<3)^(($last_data & 0b0000_0000_0000_1000)<<12)^(($last_data & 0b0000_0000_0000_0010)<<14)^(($last_data & 0b0000_0000_0000_0001)<<15)))&(0b1000_0000_0000_0000));
printf("%016b\n\n",($last_data & 0b1111_1111_1111_1110)>>1);

printf("%016b\n\n",(~((($last_data & 0b0001_0000_0000_0000)<<3)^(($last_data & 0b0000_0000_0000_1000)<<12)^(($last_data & 0b0000_0000_0000_0010)<<14)^(($last_data & 0b0000_0000_0000_0001)<<15)))&(0b1000_0000_0000_0000)|(($last_data & 0b1111_1111_1111_1110)>>1));

=cut

$str = "01236789";
$str_reverse = reverse $str;
my $str_result;
for($i=0;$i<length($str)-1;$i+=2){
    $str_result.= reverse substr($str_reverse,$i,2);
}
print $str_result;




