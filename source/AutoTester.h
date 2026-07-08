//  ***************************************************************
//  AutoTester - Self-driving smoke test, activated with -autotest
//  ------------------------------------------------------------
//  Runs a scripted sequence in one app session:  screenshot the main
//  menu, install a DMOD through the live browser pipeline, install a
//  DMOD from a URL, start a new game and screenshot it, clean up all
//  residue, write autotest/autotest_results.txt and quit.
//  See AGENTS.md for how the per-platform Test*.bat scripts use this.
//  ***************************************************************

#ifndef AutoTester_h__
#define AutoTester_h__

bool AutoTesterIsActive();
void AutoTesterInit();       //call once, right before the first MainMenuCreate
void AutoTesterUpdate();     //call every frame from App::Update
void AutoTesterOnPostDraw(); //call at the end of App::Draw (GL context current)

#endif // AutoTester_h__
