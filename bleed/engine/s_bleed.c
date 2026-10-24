#include "platform/platform.h"
#if XASH_SOUND == SOUND_BLEED
#include "sound.h"
#include <bleed_audio.h>

#define ENGINE_FRAMES   16384
#define STREAM_FRAMES   16384

static struct {
    au_stream_t stream;
    uint32_t    rate;
    uint64_t    out;
    uint64_t    played;
} s;

static uint64_t engine_played( void ) {
    return au_stream_pos( ) * SOUND_DMA_SPEED / s.rate;
}

qboolean SNDDMA_Init( void ) {
    if( au_open( ) < 0 ) {
        Con_Printf( "libaudio: no sound card\n" );
        return false;
    }

    if( au_stream_open( STREAM_FRAMES, &s.stream ) < 0 ) {
        Con_Printf( "libaudio: couldnt open a stream\n" );
        au_close( );
        return false;
    }

    s.rate = au_rate( );
    s.out  = 0;

    snd.format.speed    = SOUND_DMA_SPEED;
    snd.format.channels = 2;
    snd.format.width    = 2;
    snd.samples         = ENGINE_FRAMES * 2;
    snd.samplepos       = 0;
    snd.buffer          = Mem_Calloc( sndpool, ENGINE_FRAMES * 2 * sizeof( int16_t ));
    snd.backend_name    = "libaudio";
    snd.initialized     = true;

    Con_Printf( "libaudio: mixing at %d Hz, card at %u Hz\n", SOUND_DMA_SPEED, s.rate );
    return true;
}

void SNDDMA_Shutdown( void ) {
    Con_Printf( "Shutting down audio.\n" );
    snd.initialized = false;

    au_stream_close( );
    au_close( );

    if( snd.buffer ) {
        Mem_Free( snd.buffer );
        snd.buffer = NULL;
    }
}

void SNDDMA_BeginPainting( void ) {
    if( !snd.initialized )
        return;
    s.played = engine_played( );
    snd.samplepos = (int)(( s.played % ENGINE_FRAMES ) * 2 );
}

void SNDDMA_Submit( void ) {
    if( !snd.initialized )
        return;

    const int16_t *src = (const int16_t *)snd.buffer;
    uint64_t pos = au_stream_pos( );

    int64_t  rings_behind = (int64_t)s.played - snd.soundtime;
    uint64_t painted = (uint64_t)( snd.paintedtime + rings_behind );

    if( s.out < pos )
        s.out = pos;

    // stop where the next engine frame isnt painted yet
    while( s.out < pos + STREAM_FRAMES - 1 ) {
        uint64_t at = s.out * SOUND_DMA_SPEED;
        uint64_t i  = at / s.rate;
        if( i + 1 >= painted )
            break;

        int frac = (int)((( at % s.rate ) << 16 ) / s.rate );
        const int16_t *a = src + ( i % ENGINE_FRAMES ) * 2;
        const int16_t *b = src + (( i + 1 ) % ENGINE_FRAMES ) * 2;
        int16_t *dst = s.stream.ring + ( s.out % STREAM_FRAMES ) * 2;

        dst[0] = (int16_t)( a[0] + ((( b[0] - a[0] ) * frac ) >> 16 ));
        dst[1] = (int16_t)( a[1] + ((( b[1] - a[1] ) * frac ) >> 16 ));
        s.out++;
    }

}

void S_Activate( qboolean active ) {
}

qboolean VoiceCapture_Init( void ) {
    return false;
}

qboolean VoiceCapture_Activate( qboolean activate ) {
    return false;
}

qboolean VoiceCapture_Lock( qboolean lock ) {
    return false;
}

void VoiceCapture_Shutdown( void ) {
}

#endif
