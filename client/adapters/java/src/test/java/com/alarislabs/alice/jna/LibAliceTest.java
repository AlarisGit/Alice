package com.alarislabs.alice.jna;

import com.sun.jna.Memory;
import com.sun.jna.Native;
import com.sun.jna.Pointer;
import org.junit.BeforeClass;
import org.junit.jupiter.api.Test;

class LibAliceTest {
    @BeforeClass
    public static void setupProtectedMode() {
        Native.setProtected(true);
    }

    @Test
    void whenCallNative_thenSuccess() {
        final LibAlice lib = LibAlice.INSTANCE;


        final String requestData = "{\"key1\": \"value1\", \"key3\": \"value3\"}";
        final Pointer responseData = new Memory(1024*16);
        long responseCode;

        System.out.printf("Call get_response_c(%s)\n", requestData);
        responseCode = lib.get_response_c(requestData, responseData);
        System.out.printf("Got response code %d\n", responseCode);
        System.out.printf("Got response data: %s\n", responseData);
    }
}
