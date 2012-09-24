/*
        
        File:			WaveNetWPACrack.m
        Program:		KisMAC
		Author:			Michael Rossberg
						mick@binaervarianz.de
		Description:	KisMAC is a wireless stumbler for MacOS X.
                
        This file is part of KisMAC.

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

#import "WaveNetWPACrack.h"
#import "WaveHelper.h"
#import "WaveClient.h"
#import "WPA.h"
#import <openssl/sha.h>
#import <openssl/md5.h>

struct clientData {
    UInt8 ptkInput[WPA_NONCE_LENGTH+WPA_NONCE_LENGTH+12];
    const UInt8 *mic;
    const UInt8 *data;
    UInt32 dataLen;
    NSString *clientID;
    int wpaKeyCipher;
};


#define SHA1_MAC_LEN 20

typedef struct {
    UInt32 state[5];
} SHA1_CTX;

#pragma mark-
#pragma mark Macros for SHA1
#pragma mark-

#define rol(value, bits) (((value) << (bits)) | ((value) >> (32 - (bits))))

/* blk0() and blk() perform the initial expand. */
/* I got the idea of expanding during the round function from SSLeay */
#if BYTE_ORDER == BIG_ENDIAN
#define blk0(i) buffer[i]
#else
#define blk0(i) (buffer[i] = (rol(buffer[i], 24) & 0xFF00FF00) | \
       (rol(buffer[i], 8) & 0x00FF00FF))
#endif

#define blk(i) (buffer[i & 15] = rol(buffer[(i + 13) & 15] ^ \
	buffer[(i + 8) & 15] ^ buffer[(i + 2) & 15] ^ buffer[i & 15], 1))

/* (R0+R1), R2, R3, R4 are the different operations used in SHA1 */
//there are some intel asm versions of these we should use from cowpatty
#define R0(v,w,x,y,z,i) \
	z += ((w & (x ^ y)) ^ y) + blk0(i) + 0x5A827999 + rol(v, 5); \
	w = rol(w, 30);
#define R1(v,w,x,y,z,i) \
	z += ((w & (x ^ y)) ^ y) + blk(i) + 0x5A827999 + rol(v, 5); \
	w = rol(w, 30);
#define R2(v,w,x,y,z,i) \
	z += (w ^ x ^ y) + blk(i) + 0x6ED9EBA1 + rol(v, 5); w = rol(w, 30);
#define R3(v,w,x,y,z,i) \
	z += (((w | x) & y) | (w & x)) + blk(i) + 0x8F1BBCDC + rol(v, 5); \
	w = rol(w, 30);
#define R4(v,w,x,y,z,i) \
	z += (w ^ x ^ y) + blk(i) + 0xCA62C1D6 + rol(v, 5); \
	w=rol(w, 30);


#pragma mark-
#pragma mark SHA1 functions
#pragma mark-

/* Hash a single 512-bit block. This is the core of the algorithm. */

void SHA1Transform(UInt32 state[5], unsigned long buffer[16]) {
	UInt32 a, b, c, d, e;
	/*typedef union {
		unsigned char c[64];
		UInt32 l[16];
	} CHAR64LONG16;
	CHAR64LONG16* block;
	block = (CHAR64LONG16 *) buffer;*/

	/* Copy context->state[] to working vars */
	a = state[0];
	b = state[1];
	c = state[2];
	d = state[3];
	e = state[4];
        
	/* 4 rounds of 20 operations each. Loop unrolled. */
	R0(a,b,c,d,e, 0); R0(e,a,b,c,d, 1); R0(d,e,a,b,c, 2); R0(c,d,e,a,b, 3);
	R0(b,c,d,e,a, 4); R0(a,b,c,d,e, 5); R0(e,a,b,c,d, 6); R0(d,e,a,b,c, 7);
	R0(c,d,e,a,b, 8); R0(b,c,d,e,a, 9); R0(a,b,c,d,e,10); R0(e,a,b,c,d,11);
	R0(d,e,a,b,c,12); R0(c,d,e,a,b,13); R0(b,c,d,e,a,14); R0(a,b,c,d,e,15);
	R1(e,a,b,c,d,16); R1(d,e,a,b,c,17); R1(c,d,e,a,b,18); R1(b,c,d,e,a,19);
	R2(a,b,c,d,e,20); R2(e,a,b,c,d,21); R2(d,e,a,b,c,22); R2(c,d,e,a,b,23);
	R2(b,c,d,e,a,24); R2(a,b,c,d,e,25); R2(e,a,b,c,d,26); R2(d,e,a,b,c,27);
	R2(c,d,e,a,b,28); R2(b,c,d,e,a,29); R2(a,b,c,d,e,30); R2(e,a,b,c,d,31);
	R2(d,e,a,b,c,32); R2(c,d,e,a,b,33); R2(b,c,d,e,a,34); R2(a,b,c,d,e,35);
	R2(e,a,b,c,d,36); R2(d,e,a,b,c,37); R2(c,d,e,a,b,38); R2(b,c,d,e,a,39);
	R3(a,b,c,d,e,40); R3(e,a,b,c,d,41); R3(d,e,a,b,c,42); R3(c,d,e,a,b,43);
	R3(b,c,d,e,a,44); R3(a,b,c,d,e,45); R3(e,a,b,c,d,46); R3(d,e,a,b,c,47);
	R3(c,d,e,a,b,48); R3(b,c,d,e,a,49); R3(a,b,c,d,e,50); R3(e,a,b,c,d,51);
	R3(d,e,a,b,c,52); R3(c,d,e,a,b,53); R3(b,c,d,e,a,54); R3(a,b,c,d,e,55);
	R3(e,a,b,c,d,56); R3(d,e,a,b,c,57); R3(c,d,e,a,b,58); R3(b,c,d,e,a,59);
	R4(a,b,c,d,e,60); R4(e,a,b,c,d,61); R4(d,e,a,b,c,62); R4(c,d,e,a,b,63);
	R4(b,c,d,e,a,64); R4(a,b,c,d,e,65); R4(e,a,b,c,d,66); R4(d,e,a,b,c,67);
	R4(c,d,e,a,b,68); R4(b,c,d,e,a,69); R4(a,b,c,d,e,70); R4(e,a,b,c,d,71);
	R4(d,e,a,b,c,72); R4(c,d,e,a,b,73); R4(b,c,d,e,a,74); R4(a,b,c,d,e,75);
	R4(e,a,b,c,d,76); R4(d,e,a,b,c,77); R4(c,d,e,a,b,78); R4(b,c,d,e,a,79);
	/* Add the working vars back into context.state[] */
	state[0] += a;
	state[1] += b;
	state[2] += c;
	state[3] += d;
	state[4] += e;
}


/* SHA1InitAndUpdateFistSmall64 - Initialize new context And fillup 64*/
void SHA1InitWithStatic64(SHA1_CTX* context, unsigned char* staticT) {
	context->state[0] = 0x67452301;
	context->state[1] = 0xEFCDAB89;
	context->state[2] = 0x98BADCFE;
	context->state[3] = 0x10325476;
	context->state[4] = 0xC3D2E1F0;
        SHA1Transform(context->state,  (unsigned long *)staticT);
}

/* Add padding and return the message digest. */
void SHA1FinalFastWith20ByteData(unsigned char digest[20], SHA1_CTX* context,unsigned char data[64]) {
	UInt32 i;

        //memcpy(buffer, data, 20);
	memset(&data[21], 0, 41);
        data[20] = 128;
        data[62] = 2;
        data[63] = 160;

        SHA1Transform(context->state,  (unsigned long *)data);

	for (i = 0; i < 20; i++) {
		digest[i] = (unsigned char)
			((context->state[i >> 2] >> ((3 - (i & 3)) * 8)) & 255);
	}
}

void prepared_hmac_sha1(const SHA1_CTX *k_ipad, const SHA1_CTX *k_opad, unsigned char digest[64]) {
    SHA1_CTX ipad, opad; 

    memcpy(&ipad, k_ipad, sizeof(ipad));
    memcpy(&opad, k_opad, sizeof(opad));
    
    /* perform inner SHA1*/
    SHA1FinalFastWith20ByteData(digest, &ipad, digest); /* finish up 1st pass */ 
    
    /* perform outer SHA1 */ 
    SHA1FinalFastWith20ByteData(digest, &opad, digest); /* finish up 2nd pass */
}

#pragma mark -
#pragma mark optimized WPA password -> PMK mapping
#pragma mark -

void fastF(unsigned char *password, int pwdLen, const unsigned char *ssid, int ssidlength, const SHA1_CTX *ipadContext, const SHA1_CTX *opadContext, int count, unsigned char output[40]) {
    unsigned char digest[64], digest1[64];
    int i, j; 
    
    /* U1 = PRF(P, S || int(i)) */ 
    memcpy(digest1, ssid, ssidlength);
    digest1[ssidlength]   = 0;   
    digest1[ssidlength+1] = 0; 
    digest1[ssidlength+2] = 0;
    digest1[ssidlength+3] = (unsigned char)(count & 0xff); 
    
    fast_hmac_sha1(digest1, ssidlength+4, password, pwdLen, digest);
    
    /* output = U1 */ 
    memcpy(output, digest, SHA_DIGEST_LENGTH);

    for (i = 1; i < 4096; i++) { 
        /* Un = PRF(P, Un-1) */ 
        prepared_hmac_sha1(ipadContext, opadContext, digest); 
    
        j=0;
        /* output = output xor Un */
        ((int*)output)[j] ^= ((int*)digest)[j]; j++;
        ((int*)output)[j] ^= ((int*)digest)[j]; j++;
        ((int*)output)[j] ^= ((int*)digest)[j]; j++;
        ((int*)output)[j] ^= ((int*)digest)[j]; j++;
        ((int*)output)[j] ^= ((int*)digest)[j];
    }
} 


void fastWP_passwordHash(char *password, const unsigned char *ssid, int ssidlength, unsigned char output[40]) { 
    unsigned char k_ipad[65]; /* inner padding - key XORd with ipad */ 
    unsigned char k_opad[65]; /* outer padding - key XORd with opad */
    SHA1_CTX ipadContext, opadContext;
    int i, pwdLen = strlen(password);
    
    /* XOR key with ipad and opad values */ 
    for (i = 0; i < pwdLen; i++) { 
        k_ipad[i] = password[i] ^ 0x36; 
        k_opad[i] = password[i] ^ 0x5c;
    } 

    memset(&k_ipad[pwdLen], 0x36, sizeof k_ipad - pwdLen); 
    memset(&k_opad[pwdLen], 0x5c, sizeof k_opad - pwdLen); 

    SHA1InitWithStatic64(&ipadContext, k_ipad);
    SHA1InitWithStatic64(&opadContext, k_opad);
 
    fastF((UInt8*)password, pwdLen, ssid, ssidlength, &ipadContext, &opadContext, 1, output);
    fastF((UInt8*)password, pwdLen, ssid, ssidlength, &ipadContext, &opadContext, 2, &output[SHA_DIGEST_LENGTH]); 
} 

#pragma mark -

@implementation WaveNet(WPACrackExtension)

- (BOOL)crackWPAWithWordlist:(NSString*)wordlist andImportController:(ImportController*)im {
    char wrd[100];
    const char *ssid;
    FILE* fptr;
    unsigned int i, j, words, ssidLength, keys, curKey;
    UInt8 pmk[40], ptk[64], digest[16];
    struct clientData *c;
    WaveClient *wc;
    const UInt8 *anonce, *snonce;
    UInt8 prefix[] = "Pairwise key expansion";

    fptr = fopen([wordlist UTF8String], "r");
    if (!fptr) return NO;
    
    keys = 0;
    for (i = 0; i < [aClientKeys count]; i++) {
        if ([[aClients objectForKey:[aClientKeys objectAtIndex:i]] eapolDataAvailable])
            keys++;
    }

    NSAssert(keys!=0, @"There must be more keys");
    
    curKey = 0;
    c = malloc(keys * sizeof(struct clientData));
    
    for (i = 0; i < [aClientKeys count]; i++) {
        wc = [aClients objectForKey:[aClientKeys objectAtIndex:i]];
        if ([wc eapolDataAvailable]) {
            if ([[wc ID] isEqualToString: _BSSID]) {
                keys--;
            } else {
                if (memcmp(_rawBSSID, [[wc rawID] bytes], 6)>0) {
                    memcpy(&c[curKey].ptkInput[0], [[wc rawID] bytes] , 6);
                    memcpy(&c[curKey].ptkInput[6], _rawBSSID, 6);
                } else {
                    memcpy(&c[curKey].ptkInput[0], _rawBSSID, 6);
                    memcpy(&c[curKey].ptkInput[6], [[wc rawID] bytes] , 6);
                }
                
                anonce = [[wc aNonce] bytes]; 
                snonce = [[wc sNonce] bytes];
                if (memcmp(anonce, snonce, WPA_NONCE_LENGTH)>0) {
                    memcpy(&c[curKey].ptkInput[12],                     snonce, WPA_NONCE_LENGTH);
                    memcpy(&c[curKey].ptkInput[12 + WPA_NONCE_LENGTH],  anonce, WPA_NONCE_LENGTH);
                } else {
                    memcpy(&c[curKey].ptkInput[12],                     anonce, WPA_NONCE_LENGTH);
                    memcpy(&c[curKey].ptkInput[12 + WPA_NONCE_LENGTH],  snonce, WPA_NONCE_LENGTH);
                }

                c[curKey].data          = [[wc eapolPacket] bytes];
                c[curKey].dataLen       = [[wc eapolPacket] length];
                c[curKey].mic           = [[wc eapolMIC]    bytes];
                c[curKey].clientID      = [wc ID];
                c[curKey].wpaKeyCipher  = [wc wpaKeyCipher];
                curKey++;
            }
        }
    }

    words = 0;
    wrd[90]=0;

    ssid = [_SSID UTF8String];
    ssidLength = [_SSID lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
  
    float theTime, prevTime = clock() / (float)CLK_TCK;
    while(![im canceled] && !feof(fptr))
    {
        //get the line from the file
        fgets(wrd, 90, fptr);
        
        //get the length.  no need to account for linefeed because it will
        //be done below.  Remember indexed from 0
        i = strlen(wrd) - 1;
    
        //remove the linefeed by setting the last char to null
        //if we still have line feed chars, keep going
        while('\r' == wrd[i] || '\n' == wrd[i])
        {
            wrd[i--] = 0;
        }
        
        //switch i back to length instead of an index into the array
        //this is kinda dumb
        i = strlen(wrd);
        
        //passwords must be shorter than 63 signs
        if (i < 8 || i > 63) continue;        
        
        words++;

        if (words % 500 == 0)
        {
            theTime =clock() / (float)CLK_TCK;
            [im setStatusField:[NSString stringWithFormat:@"%d words tested    %.2f/second", words, 500.0 / (theTime - prevTime)]];
            prevTime = theTime;
        }
        
        for(j = 0; j < i; j++)
            if ((wrd[j] < 32) || (wrd[j] > 126)) break;
        if (j!=i) continue;
        
        fastWP_passwordHash(wrd, (const UInt8*)ssid, ssidLength, pmk);
    
        for (curKey = 0; curKey < keys; curKey++) {
            PRF(pmk, 32, prefix, strlen((char *)prefix), c[curKey].ptkInput, WPA_NONCE_LENGTH*2 + 12, ptk, 16);
            
            if (c[curKey].wpaKeyCipher == 1)
                fast_hmac_md5(c[curKey].data, c[curKey].dataLen, ptk, 16, digest);
            else
                fast_hmac_sha1((unsigned char*)c[curKey].data, c[curKey].dataLen, ptk, 16, digest);
            
            if (memcmp(digest, c[curKey].mic, 16) == 0) {
                _password = [[NSString stringWithFormat:@"%s for Client %@", wrd, c[curKey].clientID] retain];
                fclose(fptr);
                free(c);
                NSLog(@"Cracking was successful. Password is <%s> for Client %@", wrd, c[curKey].clientID);
                return YES;
            }
        }
    }
    
    free(c);
    fclose(fptr);
    
    _crackErrorString = [NSLocalizedString(@"The key was none of the tested passwords.", @"Error description for WPA crack.") retain];
    return NO;
}

- (void)performWordlistWPA:(NSString*)wordlist {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    BOOL successful = NO;
	
	NSParameterAssert((_isWep == encryptionTypeWPA) || (_isWep == encryptionTypeWPA2));
    NSParameterAssert(_SSID);
	NSParameterAssert([_SSID length] <= 32);
	NSParameterAssert([self capturedEAPOLKeys] > 0);
	NSParameterAssert(_password == nil);
	NSParameterAssert(wordlist);
	
	[wordlist retain];

    if ([self crackWPAWithWordlist:[wordlist stringByExpandingTildeInPath] 
               andImportController:[WaveHelper importController]]) successful = YES;
    
    [[WaveHelper importController] terminateWithCode: (successful) ? 1 : -1];
    [wordlist release];
	[pool release];
}
@end