#include <stdio.h>
#include <fenv.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#pragma STDC FENV_ACCESS ON

int rand_range(int n){
    int limit;
    int r;
    limit = RAND_MAX - (RAND_MAX % n);
    while((r = rand()) >= limit);
    return r % n; /* uniform random value in the range 0..n-1 */
}
int is_big_endian_test(void){
    int num = 1;
    if(*(char *)&num == 1){
        printf("Is little endian\n");
        return 0;
    }
    else{
        printf("Is big endian\n");
        return 1;
    }
}
void get_binary(char str_buffer[37], void *input_ptr){
    unsigned int *x, max, i;
    x = (unsigned int*) input_ptr;
    max = sizeof(*x)*8;
    strcat(str_buffer, "32'b");
    for (i = 0u; i < max; i++){
        char bin_num[1];
        *bin_num = (char) 48 + (((*x)>>(max-i-1u)) & 1);
        strcat(str_buffer, bin_num);
    }
}