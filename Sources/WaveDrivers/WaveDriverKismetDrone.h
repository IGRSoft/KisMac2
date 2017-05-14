/*
 
 File:			WaveDriverKismetDrone.h
 Program:		KisMAC
 Author:		Geordie Millar
                themacuser@gmail.com
 Changes:       Vitalii Parovishnyk(1012-2015)
 
 Description:	Scan with a Kismet drone (as opposed to kismet server) in KisMac.
 
 Details:		Tested with kismet_drone 2006.04.R1 on OpenWRT White Russian RC6 on a Diamond Digital R100
                (broadcom mini-PCI card, wrt54g capturesource)
                and kismet_drone 2006.04.R1 on Voyage Linux on a PC Engines WRAP.2E
                (CM9 mini-PCI card, madwifing)
 
 This file is part of KisMAC.
 
 Most parts of this file are based on aircrack by Christophe Devine.
 
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

#import "WaveDriver.h"
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>

#define STREAM_DRONE_VERSION 9

#define STREAM_SENTINEL      0xDECAFBAD

#define STREAM_FTYPE_VERSION 1
#define STREAM_FTYPE_PACKET  2

#define STREAM_COMMAND_FLUSH -1

#define MAX_PACKET_LEN 10240

#define SSID_SIZE 255

@class WaveDriver;

struct stream_frame_header
{
    uint32_t frame_sentinel;
    uint8_t frame_type;
    uint32_t frame_len;
} __attribute__((__packed__));

struct stream_version_packet
{
    uint16_t drone_version;
	uint8_t gps_enabled;
};

struct stream_packet_header
{
    uint32_t header_len;
    uint16_t drone_version;
    uint32_t len;
    uint32_t caplen;
    uint64_t tv_sec;
    uint64_t tv_usec;
    uint16_t quality;
    uint16_t signal;
    uint16_t noise;
    uint8_t error;
    uint8_t channel;
    uint8_t carrier;
    uint8_t encoding;
    uint32_t datarate;

    int16_t gps_lat;
    int64_t gps_lat_mant;
    int16_t gps_lon;
    int64_t gps_lon_mant;
    int16_t gps_alt;
    int64_t gps_alt_mant;
    int16_t gps_spd;
    int64_t gps_spd_mant;
    int16_t gps_heading;
    int64_t gps_heading_mant;
    int8_t gps_fix;

    uint8_t sourcename[32];
} __attribute__((__packed__));

typedef NS_ENUM(NSInteger, carrier_type)
{
    carrier_unknown = 0,
    carrier_80211b,
    carrier_80211bplus,
    carrier_80211a,
    carrier_80211g,
    carrier_80211fhss,
    carrier_80211dsss
};

typedef NS_ENUM(NSInteger, encoding_type)
{
    encoding_unknown = 0,
    encoding_cck,
    encoding_pbcc,
    encoding_ofdm
};

struct packet_parm
{
    NSInteger fuzzy_crypt;
	NSInteger fuzzy_decode;
};

typedef struct kis_packet
{
    NSUInteger len;		// The amount of data we've actually got
    NSUInteger caplen;	// The amount of data originally captured
    struct timeval ts;          // Capture timestamp
    NSInteger quality;                // Signal quality
    NSInteger signal;                 // Signal strength
    NSInteger noise;                  // Noise level
    NSInteger error;                  // Capture source told us this was a bad packet
    NSInteger channel;                // Hardware receive channel, if the drivers tell us
    NSInteger modified;               // Has moddata been populated?
    uint8_t *data;              // Raw packet data
    uint8_t *moddata;           // Modified packet data
    char sourcename[32];        // Name of the source that generated the data
	carrier_type carrier;       // Signal carrier
	encoding_type encoding;     // Signal encoding
    NSInteger datarate;               // Data rate in units of 100 kbps
    CGFloat gps_lat;              // GPS coordinates
    CGFloat gps_lon;
    CGFloat gps_alt;
    CGFloat gps_spd;
    CGFloat gps_heading;
    NSInteger gps_fix;
    struct packet_parm parm;           // Parameters from the packet source that trickle down
} kismet_packet;

typedef NS_ENUM(NSInteger, packet_type)
{
    packet_noise = -2,  // We're too short or otherwise corrupted
    packet_unknown = -1, // What are we?
    packet_management = 0, // LLC management
    packet_phy = 1, // Physical layer packets, most drivers can't provide these
    packet_data = 2 // Data frames
};

// Subtypes are a little odd because we re-use values depending on the type
typedef NS_ENUM(NSInteger, packet_sub_type)
{
    packet_sub_unknown = -1,
    // Management subtypes
    packet_sub_association_req = 0,
    packet_sub_association_resp = 1,
    packet_sub_reassociation_req = 2,
    packet_sub_reassociation_resp = 3,
    packet_sub_probe_req = 4,
    packet_sub_probe_resp = 5,
    packet_sub_beacon = 8,
    packet_sub_atim = 9,
    packet_sub_disassociation = 10,
    packet_sub_authentication = 11,
    packet_sub_deauthentication = 12,
    // Phy subtypes
    packet_sub_rts = 11,
    packet_sub_cts = 12,
    packet_sub_ack = 13,
    packet_sub_cf_end = 14,
    packet_sub_cf_end_ack = 15,
    // Data subtypes
    packet_sub_data = 0,
    packet_sub_data_cf_ack = 1,
    packet_sub_data_cf_poll = 2,
    packet_sub_data_cf_ack_poll = 3,
    packet_sub_data_null = 4,
    packet_sub_cf_ack = 5,
    packet_sub_cf_ack_poll = 6,
    packet_sub_data_qos_data = 8,
    packet_sub_data_qos_data_cf_ack = 9,
    packet_sub_data_qos_data_cf_poll = 10,
    packet_sub_data_qos_data_cf_ack_poll = 11,
    packet_sub_data_qos_null = 12,
    packet_sub_data_qos_cf_poll_nod = 14,
    packet_sub_data_qos_cf_ack_poll = 15
};

// distribution directions
typedef NS_ENUM(NSInteger, distribution_type)
{
    no_distribution = 0,
    from_distribution,
    to_distribution,
    inter_distribution,
    adhoc_distribution
};

typedef struct
{
	short unsigned int macaddr[6];
} mac_addr;

typedef NS_ENUM(NSUInteger, protocol_info_type)
{
    proto_unknown = 0,
    proto_udp, proto_misc_tcp, proto_arp, proto_dhcp_server,
    proto_cdp,
    proto_netbios, proto_netbios_tcp,
    proto_ipx,
    proto_ipx_tcp,
    proto_turbocell,
    proto_netstumbler,
    proto_lucenttest,
    proto_wellenreiter,
    proto_iapp,
    proto_leap,
    proto_ttls,
    proto_tls,
    proto_peap,
    proto_isakmp,
    proto_pptp,
};

typedef struct
{
    NSUInteger : 8 __attribute__ ((packed));
    NSUInteger : 8 __attribute__ ((packed));

    NSUInteger : 8 __attribute__ ((packed));
    NSUInteger : 1 __attribute__ ((packed));
    NSUInteger level1 : 1 __attribute__ ((packed));
    NSUInteger igmp_forward : 1 __attribute__ ((packed));
    NSUInteger nlp : 1 __attribute__ ((packed));
    NSUInteger level2_switching : 1 __attribute__ ((packed));
    NSUInteger level2_sourceroute : 1 __attribute__ ((packed));
    NSUInteger level2_transparent : 1 __attribute__ ((packed));
    NSUInteger level3 : 1 __attribute__ ((packed));
} cdp_capabilities;

#if BYTE_ORDER == BIG_ENDIAN
typedef struct {
    unsigned short subtype : 4 __attribute__ ((packed));
    unsigned short type : 2 __attribute__ ((packed));
    unsigned short version : 2 __attribute__ ((packed));

    unsigned short order : 1 __attribute__ ((packed));
    unsigned short wep : 1 __attribute__ ((packed));
    unsigned short more_data : 1 __attribute__ ((packed));
    unsigned short power_management : 1 __attribute__ ((packed));

    unsigned short retry : 1 __attribute__ ((packed));
    unsigned short more_fragments : 1 __attribute__ ((packed));
    unsigned short from_ds : 1 __attribute__ ((packed));
    unsigned short to_ds : 1 __attribute__ ((packed));
} frame_control;

typedef struct
{
    uint8_t timestamp[8];

    // This field must be converted to host-endian before being used
    NSUInteger beacon : 16 __attribute__ ((packed));

    unsigned short agility : 1 __attribute__ ((packed));
    unsigned short pbcc : 1 __attribute__ ((packed));
    unsigned short short_preamble : 1 __attribute__ ((packed));
    unsigned short wep : 1 __attribute__ ((packed));

    unsigned short unused2 : 1 __attribute__ ((packed));
    unsigned short unused1 : 1 __attribute__ ((packed));
    unsigned short ibss : 1 __attribute__ ((packed));
    unsigned short ess : 1 __attribute__ ((packed));

    NSUInteger coordinator : 8 __attribute__ ((packed));

} fixed_parameters;

#else
typedef struct
{
    unsigned short version : 2 __attribute__ ((packed));
    unsigned short type : 2 __attribute__ ((packed));
    unsigned short subtype : 4 __attribute__ ((packed));

    unsigned short to_ds : 1 __attribute__ ((packed));
    unsigned short from_ds : 1 __attribute__ ((packed));
    unsigned short more_fragments : 1 __attribute__ ((packed));
    unsigned short retry : 1 __attribute__ ((packed));

    unsigned short power_management : 1 __attribute__ ((packed));
    unsigned short more_data : 1 __attribute__ ((packed));
    unsigned short wep : 1 __attribute__ ((packed));
    unsigned short order : 1 __attribute__ ((packed));
} frame_control;

typedef struct
{
    uint8_t timestamp[8];

    // This field must be converted to host-endian before being used
    NSUInteger beacon : 16 __attribute__ ((packed));

    unsigned short ess : 1 __attribute__ ((packed));
    unsigned short ibss : 1 __attribute__ ((packed));
    unsigned short unused1 : 1 __attribute__ ((packed));
    unsigned short unused2 : 1 __attribute__ ((packed));

    unsigned short wep : 1 __attribute__ ((packed));
    unsigned short short_preamble : 1 __attribute__ ((packed));
    unsigned short pbcc : 1 __attribute__ ((packed));
    unsigned short agility : 1 __attribute__ ((packed));

    NSUInteger coordinator : 8 __attribute__ ((packed));
} fixed_parameters;
#endif

typedef struct
{
    char dev_id[128];
    uint8_t ip[4];
    char interface[128];
    cdp_capabilities cap;
    char software[512];
    char platform[128];
} cdp_packet;

typedef NS_ENUM(NSUInteger, protocol_netbios_type)
{
    proto_netbios_unknown = 0,
    proto_netbios_host, proto_netbios_master,
    proto_netbios_domain, proto_netbios_query, proto_netbios_pdcquery
};

typedef struct
{
    protocol_info_type type;
    uint8_t source_ip[4];
    uint8_t dest_ip[4];
    uint8_t misc_ip[4];
    uint8_t mask[4];
    uint8_t gate_ip[4];
    uint16_t sport, dport;
    cdp_packet cdp;
    char netbios_source[17];
    protocol_netbios_type nbtype;
    NSInteger prototype_extra;
} proto_info;

typedef NS_ENUM(NSUInteger, turbocell_type)
{
    turbocell_unknown = 0,
    turbocell_ispbase, // 0xA0
    turbocell_pollbase, // 0x80
    turbocell_nonpollbase, // 0x00
    turbocell_base // 0x40
};

typedef struct {
    packet_type type;
    packet_sub_type subtype;
    uint16_t qos; 
    NSInteger corrupt;
    NSInteger reason_code;
    struct timeval ts;
    NSInteger quality;
    NSInteger signal;
    NSInteger noise;
    char ssid[SSID_SIZE+1];
    NSInteger ssid_len;
    char sourcename[32];
    distribution_type distrib;
	NSInteger crypt_set;
    NSInteger fuzzy;
    NSInteger ess;
    NSInteger channel;
    NSInteger encrypted;
    NSInteger decoded;
    NSInteger interesting;
    carrier_type carrier;
    encoding_type encoding;
    NSInteger datarate;
    mac_addr source_mac;
    mac_addr dest_mac;
    mac_addr bssid_mac;
    NSInteger beacon;
    char beacon_info[SSID_SIZE+1];
    NSUInteger header_offset;
    proto_info proto;
    double maxrate;
    uint64_t timestamp;
    NSInteger sequence_number;
    NSInteger frag_number;
    NSInteger duration;
    NSInteger datasize;
    NSInteger turbocell_nid;
    turbocell_type turbocell_mode;
    NSInteger turbocell_sat;
    CGFloat gps_lat, gps_lon, gps_alt, gps_spd, gps_heading;
    NSInteger gps_fix;
    uint32_t ivset;
} packet_info;

@interface WaveDriverKismetDrone : WaveDriver
{
    struct sockaddr_in drone_sock, local_sock;
	int drone_fd;
	NSInteger valid;
    NSInteger resyncs;	
    NSUInteger resyncing;
    NSUInteger stream_recv_bytes;
	struct stream_frame_header fhdr;
	struct stream_version_packet vpkt;
	struct stream_packet_header phdr;
    uint8_t databuf[MAX_PACKET_LEN];
	kismet_packet *packet;
	uint8_t data[MAX_PACKET_LEN];
    uint8_t moddata[MAX_PACKET_LEN];
}

@end
