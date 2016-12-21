/*
   *  FCS.h
   *  KisMAC
   *
   *  Created by mick on Fri Jul 23 2004.
   *  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
   *
   */

#ifdef __cplusplus
extern "C" {
	#endif

    uint32_t UPDC32(uint32_t octet, uint32_t crc);
    uint32_t CRC32_block(const uint8_t *p, size_t n, uint32_t crc);

	#ifdef __cplusplus
	}
#endif