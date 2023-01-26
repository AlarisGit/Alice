package com.alarislabs.alice.jna;

import com.sun.jna.LastErrorException;
import com.sun.jna.Library;
import com.sun.jna.Native;
import com.sun.jna.Pointer;

public interface LibAlice extends Library {
    LibAlice INSTANCE = Native.load("alice2", LibAlice.class);

//  unsigned int get_response_c(const char *, char *);
    int get_license(String req, Pointer resp) throws LastErrorException;;
}

