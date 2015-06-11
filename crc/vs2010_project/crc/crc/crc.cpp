/*
 * 三种计算CRC的方式
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <io.h>

#define alt_8    char
#define alt_u8   unsigned char
#define alt_32   int
#define alt_u32  unsigned int
#define alt_64   long long
#define alt_u64  unsigned long long


//位翻转函数
alt_u64 Reflect(alt_u64 ref,alt_u8 ch)
{	
	int i;
	alt_u64 value = 0;
	for( i = 1; i < ( ch + 1 ); i++ )
	{
		if( ref & 1 )
			value |= 1 << ( ch - i );
		ref >>= 1;
	}
	return value;
}


//标准的CRC32多项式
#define poly  0x04C11DB7
//翻转的CRC32多项式
#define upoly 0xEDB88320



alt_u32 crc32_bit(alt_u8 *ptr, alt_u32 len, alt_u32 gx)
{
    alt_u8 i;
	alt_u32 crc = 0xffffffff;
    while( len-- )
    {
        for( i = 1; i != 0; i <<= 1 )
        {
            if( ( crc & 0x80000000 ) != 0 )
			{
				crc <<= 1;
				crc ^= gx;
			}
            else 
				crc <<= 1;
            if( ( *ptr & i ) != 0 ) 
				crc ^= gx;
        }
        ptr++;
    }
    return ( Reflect(crc,32) ^ 0xffffffff );
}


alt_u32 Table1[256];
alt_u32 Table2[256];


 // 生成CRC32 普通表 , 第二项是04C11DB7
void gen_direct_table(alt_u32 *table)
{
	alt_u32 gx = 0x04c11db7;
	unsigned long i32, j32;
	unsigned long nData32;
	unsigned long nAccum32;
	for ( i32 = 0; i32 < 256; i32++ )
	{
		nData32 = ( unsigned long )( i32 << 24 );
		nAccum32 = 0;
		for ( j32 = 0; j32 < 8; j32++ )
		{
			if ( ( nData32 ^ nAccum32 ) & 0x80000000 )
				nAccum32 = ( nAccum32 << 1 ) ^ gx;
			else
				nAccum32 <<= 1;
			nData32 <<= 1;
		}
		table[i32] = nAccum32;
	}
}


// 生成CRC32 翻转表 第二项是77073096
void gen_normal_table(alt_u32 *table)
{
	alt_u32 gx = 0x04c11db7;
	alt_u32 temp,crc;
	for(int i = 0; i <= 0xFF; i++) 
	{
		temp=Reflect(i, 8);
		table[i]= temp<< 24;
		for (int j = 0; j < 8; j++)
		{
			unsigned long int t1,t2;
			unsigned long int flag=table[i]&0x80000000;
			t1=(table[i] << 1);
			if(flag==0)
			t2=0;
			else
			t2=gx;
			table[i] =t1^t2 ;
		}
		crc=table[i];
		table[i] = Reflect(table[i], 32);
	}
}

alt_u32 DIRECT_TABLE_CRC(alt_u8 *ptr,int len, alt_u32 * table) 
{
	alt_u32 crc = 0xffffffff; 
	alt_u8 *p= ptr;
	int i;
	for ( i = 0; i < len; i++ )
		crc = ( crc << 8 ) ^ table[( crc >> 24 ) ^ (alt_u8)Reflect((*(p+i)), 8)];
	return ~(alt_u32)Reflect(crc, 32) ;
}


alt_u32 Reverse_Table_CRC(alt_u8 *data, alt_32 len, alt_u32 * table)
{
	alt_u32 crc = 0xffffffff;  
	alt_u8 *p = data;
	int i;
	for(i=0; i <len; i++)
		crc =  table[( crc ^( *(p+i)) ) & 0xff] ^ (crc >> 8);
	return  ~crc ; 
}

int char2bin(char val)
{
	int value = 0;
	if(val >= 'a' && val <= 'f')
    {
    	value = val - 'a' + 10;
    }
    else if(val >= 'A' && val <= 'F')
    {
    	value = val - 'A' + 10;
    }
    else if(val >= '0' && val <= '9')
    {
    	value = val - '0';
    }
	return value;
}

int hex2bin(char val1,char val2)
{
	return char2bin(val1)*16+char2bin(val2);
}

int main(int argc,char** argv)
{
	//根据输入的16进制字符串创建数组
    if(argc<2)
    {
    	printf("uage: crc <frame_hex_string>\n");
        printf("example: crc 11223344aabbcc\n");
        return 0;
    }
    char* str = argv[1];
    int length = strlen(str);
    if(length%2!=0)
    {
    	printf("hex string length is not even number\n");
        return 0;
    }
    alt_u8 *data = (alt_u8*)malloc(length*sizeof(alt_u8));
    for(int i=0;i<=length-2;i+=2)
    {
    	//printf("%c%c ",str[i],str[i+1]);
        //printf("%d \n",char2bin(str[i]));
        //printf("%d ",hex2bin(str[i],str[i+1]));
        *(data+i/2) = hex2bin(str[i],str[i+1]);
    }
    
	//生成翻转表，是官方推荐的，故称其为normal_table
	gen_normal_table(Table2);
	//使用翻转表，官方推荐的，很快
    printf("CRC:%08x\n",Reverse_Table_CRC(data,length/2,Table2));
    
    free(data);
    return 0;
}