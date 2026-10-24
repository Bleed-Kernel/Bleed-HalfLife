#include "platform/platform.h"
#if XASH_INPUT == INPUT_BLEED
#include "input.h"
#include "client.h"
#include "vgui_draw.h"
#include "bleed_platform.h"

// keycodes from the desktop are ps/2 set 1 scancodes, same table as the dos port
static const byte scantokey[128] = {
    0,           K_ESCAPE,    '1',         '2',         '3',          '4',         '5',          '6',
    '7',         '8',         '9',         '0',         '-',          '=',         K_BACKSPACE,  K_TAB,
    'q',         'w',         'e',         'r',         't',          'y',         'u',          'i',
    'o',         'p',         '[',         ']',         K_ENTER,      K_CTRL,      'a',          's',
    'd',         'f',         'g',         'h',         'j',          'k',         'l',          ';',
    '\'',        '`',         K_SHIFT,     '\\',        'z',          'x',         'c',          'v',
    'b',         'n',         'm',         ',',         '.',          '/',         K_SHIFT,      K_KP_MUL,
    K_ALT,       K_SPACE,     K_CAPSLOCK,  K_F1,        K_F2,         K_F3,        K_F4,         K_F5,
    K_F6,        K_F7,        K_F8,        K_F9,        K_F10,        K_PAUSE,     0,            K_HOME,
    K_UPARROW,   K_PGUP,      K_KP_MINUS,  K_LEFTARROW, K_KP_5,       K_RIGHTARROW, K_KP_PLUS,   K_END,
    K_DOWNARROW, K_PGDN,      K_INS,       K_DEL,       0,            0,           '\\',         K_F11,
    K_F12,
};

static struct {
    int      x, y;
    float    dx, dy;
    uint32_t buttons;
    qboolean grabbed;
    qboolean text;
} in;

static void mouse_buttons( uint32_t buttons ) {
    static const uint32_t masks[] = { CS_BUTTON_LEFT, CS_BUTTON_RIGHT, CS_BUTTON_MIDDLE };
    uint32_t changed = buttons ^ in.buttons;

    for( int i = 0; i < ARRAYSIZE( masks ); i++ ) {
        if( changed & masks[i] )
            IN_MouseEvent( i, ( buttons & masks[i] ) ? true : false );
    }
    in.buttons = buttons;
}

static void key_event( const cs_event_t *ev ) {
    qboolean down = Bleed_KeyDown( ev->key_action ) ? true : false;
    int key = ev->keycode < ARRAYSIZE( scantokey ) ? scantokey[ev->keycode] : 0;

    if( !key )
        return;

    // typing goes in as characters
    if( in.text && down ) {
        if( Bleed_KeyCtrl( ev->keymod )) {
            // how the console knows ctrl+c, ctrl+v and the like
            if( key >= 'a' && key <= 'z' ) {
                CL_CharEvent( key - 'a' + 1 );
                return;
            }
        } else if( key != '`' || cls.key_dest != key_console ) {
            int c = Bleed_KeyChar( ev->keycode, ev->keymod );
            if( c >= 32 && c < 127 )
                CL_CharEvent( c );
        }
    }

    Key_Event( key, down );
}

static void focus_event( qboolean gained ) {
    if( gained ) {
        host.status = HOST_FRAME;
        if( cls.key_dest == key_game )
            IN_ActivateMouse( );
        return;
    }

    host.status = HOST_NOFOCUS;
    if( cls.key_dest == key_game ) {
        Key_ClearStates( );
        IN_DeactivateMouse( );
    }
}

void Platform_RunEvents( void ) {
    cs_event_t ev;

    if( !bleed_window )
        return;

    while( cs_event_wait( &ev, 0 )) {
        switch( ev.type ) {
        case CS_EV_KEY:
            key_event( &ev );
            break;

        case CS_EV_MOUSE:
            in.x = ev.x;
            in.y = ev.y;
            mouse_buttons( ev.buttons );
            break;

        case CS_EV_MOUSE_RELATIVE:
            in.dx += ev.x;
            in.dy += ev.y;
            mouse_buttons( ev.buttons );
            break;

        case CS_EV_WHEEL:
            for( int i = 0; i < abs( ev.wheel ); i++ )
                IN_MWheelEvent( ev.wheel > 0 ? 1 : -1 );
            break;

        case CS_EV_RESIZE:
            Bleed_WindowResized( ev.w, ev.h );
            break;

        case CS_EV_FOCUS:
            focus_event( ev.focused ? true : false );
            break;

        case CS_EV_CLOSE_REQUEST:
            CL_RequestQuit( "window closed" );
            break;

        default:
            break;
        }
    }
}

void Platform_MouseMove( float *x, float *y ) {
    *x = in.dx;
    *y = in.dy;
    in.dx = in.dy = 0;
}

void GAME_EXPORT Platform_GetMousePos( int *x, int *y ) {
    if( x ) *x = in.x;
    if( y ) *y = in.y;
}

void GAME_EXPORT Platform_SetMousePos( int x, int y ) {
}

void Platform_PreCreateMove( void ) {
}// desktop owns the pointer so i get to stub this

qboolean Platform_GetMouseGrab( void ) {
    return in.grabbed;
}

void Platform_SetMouseGrab( qboolean enable ) {
    if( !bleed_window || in.grabbed == enable )
        return;

    in.grabbed = enable;
    in.dx = in.dy = 0;
    cs_pointer_lock( bleed_window, enable ? 1 : 0 );
}

void Platform_SetCursorType( VGUI_DefaultCursor type ) {
    host.mouse_visible = type != dc_user && type != dc_none;
    VGui_UpdateInternalCursorState( type );
}

void Platform_EnableTextInput( qboolean enable, int x, int y, int w, int h ) {
    in.text = enable;
}

int Platform_GetClipboardText( char *buffer, size_t size ) {
    if( size )
        buffer[0] = 0;
    return 0;
}

void Platform_SetClipboardText( const char *buffer ) {
}

#endif // XASH_INPUT == INPUT_BLEED
