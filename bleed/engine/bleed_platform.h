#pragma once

#include <crime/crime.h>

extern cs_window_t *bleed_window;

void Bleed_WindowResized( int width, int height );

int Bleed_KeyDown( uint8_t action );
int Bleed_KeyCtrl( uint8_t keymod );
int Bleed_KeyChar( uint16_t keycode, uint8_t keymod );
