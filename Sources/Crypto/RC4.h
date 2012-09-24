/*
        
        File:			RC4.h
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
#ifdef __cplusplus
extern "C" {
#endif

#ifndef __RC4_H
#define __RC4_H

#define IV_SIZE 3

#define N 256

extern unsigned char Identity[N];

typedef struct RC4_t {
  unsigned char S[N];
  unsigned char i, j;
} RC4;

void RC4init(RC4 *that);
void keyStep(RC4 *that, unsigned char *K, int l);
void RC4InitWithKey(RC4 *that, unsigned char *K, int l);
int step(RC4 *that);
int SInverse(RC4 *that, int x);
int keyGuess(RC4 *that, int B,int out);
int isOk(RC4 *that, int B);
int tryIV(unsigned char *key, int B,int out);
int tryIVx(unsigned char *key, int B,int out, int* byte);
void setupIdentity(void);

#endif

#ifdef __cplusplus
}
#endif
