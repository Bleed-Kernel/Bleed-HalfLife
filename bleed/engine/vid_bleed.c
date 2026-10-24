#include "platform/platform.h"
#if XASH_VIDEO == VIDEO_BLEED
#include "client.h"
#include "vid_common.h"
#include "bleed_platform.h"

cs_window_t *bleed_window;

static struct {
    uint32_t *pixels;
    int       width;
    int       height;
    uint32_t *x_map;
    int       x_map_out;
} sw;

static vidmode_t modes[] = {
    { "640x480",   640,  480 },
    { "800x600",   800,  600 },
    { "1024x768",  1024, 768 },
    { "1280x720",  1280, 720 },
    { "1280x960",  1280, 960 },
    { "1920x1080", 1920, 1080 },
    { "1280x720",  1280, 720 },
};

void Platform_Minimize_f( void ) {
}

platform_orientation_t Platform_GetDisplayOrientation( void ) {
    return ORIENTATION_LANDSCAPE;
}

void GL_SwapBuffers( void ) {
}

int GL_SetAttribute( int attr, int val ) {
    return 0;
}

int GL_GetAttribute( int attr, int *val ) {
    return 0;
}

void *GL_GetProcAddress( const char *name ) {
    return NULL;
}

void GL_UpdateSwapInterval( void ) {
}

int R_MaxVideoModes( void ) {
    return ARRAYSIZE( modes );
}

vidmode_t *R_GetVideoMode( int num ) {
    if( num < 0 || num >= ARRAYSIZE( modes ))
        return NULL;
    return &modes[num];
}

ref_window_type_t R_GetWindowHandle( void **handle, ref_window_type_t type ) {
    return REF_WINDOW_TYPE_NULL;
}

// render at the windows size, same as a resizable sdl window
void Bleed_WindowResized( int width, int height ) {
    int render_w = width;
    int render_h = height;

    VID_SetDisplayTransform( &render_w, &render_h );
    R_SaveVideoMode( width, height, render_w, render_h, false );
}

qboolean R_Init_Video( ref_graphic_apis_t type ) {
    if( type != REF_SOFTWARE )
        return false;

    if( !bleed_window ) {
        bleed_window = cs_window_open( DEFAULT_MODE_WIDTH, DEFAULT_MODE_HEIGHT, "Half-Life" );
        if( !bleed_window ) {
            Con_Printf( S_ERROR "the Crime-Scene desktop isnt running, nowhere to draw\n" );
            return false;
        }
    }

    if( !VID_SetMode( ))
        return false;

    host.renderinfo_changed = false;
    return true;
}

void R_Free_Video( void ) {
    free( sw.pixels );
    free( sw.x_map );
    memset( &sw, 0, sizeof( sw ));

    if( bleed_window ) {
        cs_window_close( bleed_window );
        bleed_window = NULL;
    }

    ref.dllFuncs.GL_ClearExtensions( );
}

qboolean VID_SetMode( void ) {
    int width  = window_width.value;
    int height = window_height.value;

    if( width < VID_MIN_WIDTH || height < VID_MIN_HEIGHT ) {
        width  = DEFAULT_MODE_WIDTH;
        height = DEFAULT_MODE_HEIGHT;
    }

    return R_ChangeDisplaySettings( width, height, WINDOW_MODE_WINDOWED ) == rserr_ok;
}

rserr_t R_ChangeDisplaySettings( int width, int height, window_mode_t window_mode ) {
    if( !bleed_window )
        return rserr_unknown;

    if( width != bleed_window->width || height != bleed_window->height )
        cs_window_resize( bleed_window, width, height );

    refState.window_mode = WINDOW_MODE_WINDOWED;
    Bleed_WindowResized( bleed_window->width, bleed_window->height );
    return rserr_ok;
}

qboolean SW_CreateBuffer( int width, int height, uint *stride, uint *bpp, uint *r, uint *g, uint *b ) {
    uint32_t *pixels = malloc( (size_t)width * height * sizeof( uint32_t ));
    if( !pixels )
        return false;

    free( sw.pixels );
    sw.pixels = pixels;
    sw.width  = width;
    sw.height = height;

    // the window is 0x00RRGGBB
    *stride = width;
    *bpp    = 4;
    *r      = 0x00FF0000;
    *g      = 0x0000FF00;
    *b      = 0x000000FF;
    return true;
}

void *SW_LockBuffer( void ) {
    return sw.pixels;
}

static void blit_stretched( void ) {
    int out_w = bleed_window->width;
    int out_h = bleed_window->height;
    int last_src_y = -1;

    if( out_w != sw.x_map_out ) {
        uint32_t *map = realloc( sw.x_map, (size_t)out_w * sizeof( uint32_t ));
        if( !map )
            return;
        sw.x_map = map;
        sw.x_map_out = out_w;
        for( int x = 0; x < out_w; x++ )
            sw.x_map[x] = (uint32_t)((uint64_t)x * sw.width / out_w );
    }

    for( int y = 0; y < out_h; y++ ) {
        int src_y = (int)((int64_t)y * sw.height / out_h );
        uint32_t *dst = bleed_window->pixels + (size_t)y * bleed_window->pitch;

        // stretched taller than the picture, this row is the one above again
        if( src_y == last_src_y ) {
            memcpy( dst, dst - bleed_window->pitch, (size_t)out_w * sizeof( uint32_t ));
            continue;
        }
        last_src_y = src_y;

        const uint32_t *src = sw.pixels + (size_t)src_y * sw.width;
        for( int x = 0; x < out_w; x++ )
            dst[x] = src[sw.x_map[x]];
    }
}

void SW_UnlockBuffer( void ) {
    if( !bleed_window || !sw.pixels )
        return;

    if( bleed_window->width == sw.width && bleed_window->height == sw.height ) {
        for( int y = 0; y < sw.height; y++ )
            memcpy( bleed_window->pixels + (size_t)y * bleed_window->pitch,
                    sw.pixels + (size_t)y * sw.width, (size_t)sw.width * sizeof( uint32_t ));
    } else {
        blit_stretched( );
    }

    cs_window_commit( bleed_window, 0, 0, bleed_window->width, bleed_window->height );
}

void VID_Info_f( void ) {
    if( bleed_window )
        Con_Printf( "Crime-Scene window %dx%d, rendering %dx%d\n", bleed_window->width, bleed_window->height, sw.width, sw.height );
}

#endif
