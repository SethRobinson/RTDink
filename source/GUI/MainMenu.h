#ifndef MainMenu_h__
#define MainMenu_h__

#include "App.h"

#define BACK_BUTTON_Y 293
Entity * MainMenuCreate(Entity *pParentEnt, bool bFadeIn = false);
Entity *  AddTitle( Entity *pEnt, string title);
string GetNextDMODToInstall(bool &bIsCommandLineInstall, const bool bDeleteCommandLineParms); //defined in MainMenu.cpp, used by AutoTester too
#endif // MainMenu_h__