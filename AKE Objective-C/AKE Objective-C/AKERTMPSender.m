//
//  AKERTMPSender.m
//  AKE Objective-C
//
//  Created by akanchi on 2019/8/18.
//  Copyright © 2019 akanchi. All rights reserved.
//

#import "AKERTMPSender.h"
#import <rtmp.h>
#import "AKEData.h"
#import "AKEAVQueue.h"
#import "AKEAVPacket.h"

//@see: https://ffmpeg.org/doxygen/0.5/flvenc_8c-source.html
char *put_byte(char *output, uint8_t nVal)
{
    output[0] = nVal;
    return output + 1;
}
char *put_be16(char *output, uint16_t nVal)
{
    output[1] = nVal & 0xff;
    output[0] = nVal >> 8;
    return output + 2;
}
char *put_be24(char *output, uint32_t nVal)
{
    output[2] = nVal & 0xff;
    output[1] = nVal >> 8;
    output[0] = nVal >> 16;
    return output + 3;
}
char *put_be32(char *output, uint32_t nVal)
{
    output[3] = nVal & 0xff;
    output[2] = nVal >> 8;
    output[1] = nVal >> 16;
    output[0] = nVal >> 24;
    return output + 4;
}
char *put_be64(char *output, uint64_t nVal)
{
    output = put_be32(output, nVal >> 32);
    output = put_be32(output, nVal);
    return output;
}
char *put_amf_string(char *c, const char *str)
{
    uint16_t len = strlen(str);
    c = put_be16(c, len);
    memcpy(c, str, len);
    return c + len;
}
char *put_amf_double(char *c, double d)
{
    *c++ = AMF_NUMBER;  /* type: Number */
    {
        unsigned char *ci, *co;
        ci = (unsigned char *)&d;
        co = (unsigned char *)c;
        co[0] = ci[7];
        co[1] = ci[6];
        co[2] = ci[5];
        co[3] = ci[4];
        co[4] = ci[3];
        co[5] = ci[2];
        co[6] = ci[1];
        co[7] = ci[0];
    }
    return c + 8;
}

@interface AKERTMPSender ()

@property (nonatomic, unsafe_unretained) RTMP *rtmp;
@property (nonatomic, strong) NSString *fmsUrl;
@property (nonatomic, strong) NSString *metaData;

@property (nonatomic, strong) NSThread *sendThread;

@property (nonatomic, assign) BOOL hasSendMetadata;

@end

@implementation AKERTMPSender

- (instancetype)init {
    self = [super init];
    if (self) {
        _rtmp = RTMP_Alloc();
        RTMP_Init(_rtmp);
        _fmsUrl = @"rtmp://192.168.2.67/live/livestream2";
        _sendThread = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
    }

    return self;
}

- (void)start {
    [_sendThread start];
}

- (BOOL)connect {
    char *url = (char *)[_fmsUrl UTF8String];
    RTMP_SetupURL(_rtmp, url);
    if (RTMP_SetupURL(_rtmp, url) <= 0) {
        return NO;
    }

    RTMP_EnableWrite(_rtmp);

    if (RTMP_Connect(_rtmp, 0) <= 0) {
        return NO;
    }

    if (RTMP_ConnectStream(_rtmp, 0) <= 0) {
        return NO;
    }

    [self setChunkSize:4096];

    [self start];

    return YES;
}

- (void)sendPacket:(uint8_t)type data:(NSData *)data timestamp:(uint32_t)timestamp {
    if (!_rtmp || data.length == 0) {
        return;
    }

    RTMPPacket p;
    RTMPPacket_Alloc(&p, (uint32_t)data.length);

    p.m_hasAbsTimestamp = 0;
    p.m_packetType = type;
    p.m_nChannel = type == RTMP_PACKET_TYPE_AUDIO ? 0x04 : 0x05;
    p.m_headerType = RTMP_PACKET_SIZE_LARGE;
    p.m_nTimeStamp = timestamp;
    p.m_nInfoField2 = self->_rtmp->m_stream_id;
    p.m_nBodySize = (uint32_t)data.length;

    [data getBytes:p.m_body length:data.length];

    int ret = -1;
    if (RTMP_IsConnected(self->_rtmp)) {
        ret = RTMP_SendPacket(self->_rtmp, &p, 0);
    }

    RTMPPacket_Free(&p);
}

- (void)sendMetadata {

    char body[1024] = { 0 };
    char * p = (char *)body;

    p = put_byte(p, AMF_STRING);
    p = put_amf_string(p, "@setDataFrame");
    p = put_byte(p, AMF_STRING);
    p = put_amf_string(p, "onMetaData");
    p = put_byte(p, AMF_OBJECT);
    p = put_amf_string(p, "encoder");
    p = put_byte(p, AMF_STRING);
    p = put_amf_string(p, "AKE");

    p = put_amf_string(p, "encoder_authors");
    p = put_byte(p, AMF_STRING);
    p = put_amf_string(p, "AKE");

    p = put_amf_string(p, "width");
    p = put_amf_double(p, 720);

    p = put_amf_string(p, "height");
    p = put_amf_double(p, 1280);

    p = put_amf_string(p, "framerate");
    p = put_amf_double(p, 20);

    p = put_amf_string(p, "videocodecid");
    p = put_amf_double(p, 7);

    p = put_amf_string(p, "audiodatarate");
    p = put_amf_double(p, 0);

    p = put_amf_string(p, "audiosamplerate");
    p = put_amf_double(p, 128);

    p = put_amf_string(p, "audiosamplesize");
    p = put_amf_double(p, 44100);

    p = put_amf_string(p, "audiocodecid");
    p = put_amf_double(p, 10);

    p = put_amf_string(p, "audiochannels");
    p = put_amf_double(p, 2);

    p = put_amf_string(p, "canSeekToEnd");
    p = put_byte(p, AMF_STRING);
    p = put_amf_string(p, "false");

    p = put_amf_string(p, "");
    p = put_byte(p, AMF_OBJECT_END);

    NSData *metaData = [NSData dataWithBytes:body length:p-body];

    [self sendPacket:RTMP_PACKET_TYPE_INFO data:metaData timestamp:0];
}

#pragma mark - private
- (void)setChunkSize:(uint32_t)size {
    RTMPPacket p;
    RTMPPacket_Alloc(&p, 4);

    p.m_packetType = 1;
    p.m_nChannel = 0x02;
    p.m_headerType = RTMP_PACKET_SIZE_LARGE;
    p.m_nTimeStamp = 0;
    p.m_nInfoField2 = 0;
    p.m_nBodySize = 4;

    p.m_body[3] = size & 0xff;
    p.m_body[2] = size >> 8;
    p.m_body[1] = size >> 16;
    p.m_body[0] = size >> 24;

    self->_rtmp->m_outChunkSize = size;

    RTMP_SendPacket(self->_rtmp, &p, 0);
    RTMPPacket_Free(&p);
}

- (void)run {
    while (true) {
        if (!self.hasSendMetadata) {
            [self sendMetadata];
            self.hasSendMetadata = YES;
        }

        NSArray<AKEAVPacket *> *packets = [[AKEAVQueue sharedInstance] dequeue];
        if (packets.count == 0) {
            [NSThread sleepForTimeInterval:0.01];
            continue;
        }

        for (AKEAVPacket *p in packets) {
            [self sendPacket:p.type data:[p.data read_data:[p.data size]] timestamp:p.dts];
        }
    }
}

@end
