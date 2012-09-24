/*
        
        File:			RC4.mm
        Program:		KisMAC
	Author:			Airsnort Team, changes by Michael Ro§berg
				mick@binaervarianz.de
	Description:		KisMAC is a wireless stumbler for MacOS X.
                
        This most parts of this file have been take from Airsnort.

    KisMAC is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License, version 2,
    as published by the Free Software Foundation;

    KisMAC is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with KisMAC; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#include <Cocoa/Cocoa.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

#include "RC4.h" 

#define Q 255

#define NORM(x) ((x) & Q)
#define SWAP(i,j) do {int t = that->S[i]; that->S[i] = that->S[j]; that->S[j] = t;} while(0)

unsigned char Identity[N];

void RC4init(RC4 *that) {
  memcpy(that->S, Identity, sizeof(unsigned char) * N);
  that->i = that->j = 0;
}

void keyStep(RC4 *that, unsigned char *K,int l) {
  that->j += (that->S)[that->i] + K[that->i % l];
  SWAP(that->i, that->j);
  (that->i)++;
}

void RC4InitWithKey(RC4 *that, unsigned char *K, int l) {
    int a;

    RC4init(that);
    for (a = 0; a < N; a++) keyStep(that, K, l);
    that->i = that->j = 0;
}

int step(RC4 *that) {
  (that->i)++;
  that->j += that->S[that->i];
  SWAP(that->i, that->j);
  return (that->S[NORM(that->S[that->i] + that->S[that->j])]);
}

int SInverse(RC4 *that, int x) {
  int a;
  for(a = 0; a < N; a++) if (that->S[a] == x) return(a);

  printf("Reality Error #1");
  exit(1);
}

/* Returns the key guess, the assumptions are as follows:
   1. The IV is assumed to be IV_SIZE bytes, B is which byte of the key we seek
   3. The system is in a 'resolved state' and is at time IV_SIZE+B of keying
   4. out is the first output byte of the cypher 
*/
int keyGuess(RC4 *that, int B,int out) { 
  return (NORM(SInverse(that, out) - that->j - that->S[IV_SIZE+B]));
}

/* Trys to guess key at location B, Assumptions:
   IV_SIZE is the size of the initialization vector.
   key is the Initialization Vector+Key
   key[x] where x<B+IV_SIZE is known, and in unsigned char *key.
   out is the first byte of the cypher output.

   that function returns -1 if no guess can be made (often), and even
   is made it might be wrong, but the chances of it being right are >= 5%, so
   just get a bunch of guesses and look for the answer that shows up the most
*/
int tryIV(unsigned char *key, int B, int out) {
    int a;
    RC4 rc;
    RC4init(&rc);
    
    for(a = 0; a < IV_SIZE; a++) keyStep(&rc, key, 16);
    /* Checks if the system is in a state where we can use keyGuess. */
    if (!(rc.S[1] < IV_SIZE && NORM(rc.S[1] + rc.S[rc.S[1]]) == IV_SIZE + B)) return(-1);
    for(a = IV_SIZE; a < IV_SIZE+B; a++) keyStep(&rc, key, 16);
    return keyGuess(&rc, B, out);
}

/* This is a test function trying to implement an extended scoring system
   there are certain weak packets that are "weaker", but i dont have enough
   weak packets to prove
*/
int tryIVx(unsigned char *key, int B, int out, int* byte) {
    int a;
    RC4 rc;
    RC4init(&rc);
    
    for(a = 0; a < IV_SIZE; a++) keyStep(&rc, key, 16);
    /* Checks if the system is in a state where we can use keyGuess. */
    if (!(rc.S[1] < IV_SIZE && (NORM(rc.S[1] + rc.S[rc.S[1]])) == IV_SIZE + B)) {
        return 0;
    }
    
    for(a = IV_SIZE; a < IV_SIZE+B; a++) keyStep(&rc, key, 16);
    *byte=keyGuess(&rc, B, out);
    if (*byte<0) return 0;
     
    if(rc.S[1] == rc.S[rc.S[1]] || rc.S[1] == rc.S[NORM(rc.S[1] + rc.S[rc.S[1]])] || rc.S[rc.S[1]] == rc.S[NORM(rc.S[1] + rc.S[rc.S[1]])])
        a=130;
    else
        a=50;
    
    if (*byte >= 32 && *byte <= 127) a++;

    return a;
}

void setupIdentity() {
  int a;
  for(a = 0; a < N; a++) Identity[a] = a;
}

#ifdef __cplusplus
}
#endif
