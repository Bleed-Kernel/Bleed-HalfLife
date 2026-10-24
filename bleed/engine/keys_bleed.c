#include <bleed/keyboard.h>

int Bleed_KeyDown( uint8_t action ) {
    return action == KEY_DOWN;
}

int Bleed_KeyCtrl( uint8_t keymod ) {
    return ( keymod & KEYMOD_CTRL ) != 0;
}

// the character the key types with the shift and caps the desktop sent
int Bleed_KeyChar( uint16_t keycode, uint8_t keymod ) {
    keyboard_event_t ev = { .keycode = keycode, .action = KEY_DOWN, .keymod = keymod };
    return (unsigned char)tty_key_to_ascii( &ev );
}
