#ifndef MainMenu_h__
#define MainMenu_h__

#include "App.h"

#define BACK_BUTTON_Y 293
Entity * MainMenuCreate(Entity *pParentEnt, bool bFadeIn = false);
Entity *  AddTitle( Entity *pEnt, string title);
#endif // MainMenu_h__