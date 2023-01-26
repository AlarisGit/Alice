#include "stdio.h"
#include "stdlib.h"

unsigned int get_license(const char *, char *);

int main(){
//    unsigned int value = get_value(0x01);
//    printf("Got C  value %x\n", value);

//    value = get_value_go(0x02);
//    printf("Got GO value %x\n", value);

    const char *sRequestData = "{\"key1\": \"value1\", \"key3\": \"value3\"}";
    char *sResponseData = malloc(1024*16);
    unsigned long uResponseCode;

    printf("Call get_response_c(%s)\n", sRequestData);
    uResponseCode = get_license(sRequestData, sResponseData);
    printf("Got response code %ld\n", uResponseCode);
    printf("Got response data: %s\n", sResponseData);
}

