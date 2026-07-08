//  ***************************************************************
//  AutoTester - see AutoTester.h for what this is
//  ***************************************************************

#include "PlatformPrecomp.h"
#include "AutoTester.h"
#include "App.h"
#include "dink/dink.h"
#include "GUI/MainMenu.h"
#include "GUI/BrowseMenu.h"
#include "GUI/DMODMenu.h"
#include "GUI/DMODInstallMenu.h"
#include "GUI/PauseMenu.h"
#include "Entity/EntityUtils.h"
#include "Renderer/SoftSurface.h"
#include <cstdio>

//The two test DMODs.  The browser test looks this name up in the live dinknetwork.com list, so it
//must match the "Title" field of the api response exactly (case-insensitive).  Keep both small.
const string AUTOTEST_BROWSER_DMOD_NAME = "Cycles of Evil";
//plain http with no redirect (the Mac build uses native NetHTTP, no TLS), tiny 24K download
const string AUTOTEST_URL_DMOD_URL = "http://dinknetwork.com/download/dmods/abcdefgh.dmod";

enum eAutoTestStep
{
	STEP_INACTIVE = 0,
	STEP_WAIT_MAINMENU,
	STEP_SHOT_MAINMENU,
	STEP_OPEN_DMOD_MENU,
	STEP_OPEN_BROWSER,
	STEP_START_BROWSER_INSTALL,
	STEP_WAIT_BROWSER_INSTALL,
	STEP_DISMISS_INSTALL_1,
	STEP_WAIT_MAINMENU_2,
	STEP_START_URL_INSTALL,
	STEP_WAIT_URL_INSTALL,
	STEP_DISMISS_INSTALL_2,
	STEP_WAIT_MAINMENU_3,
	STEP_START_NEWGAME,
	STEP_WAIT_NEWGAME,
	STEP_SHOT_NEWGAME,
	STEP_QUIT_GAME,
	STEP_RECOVER,
	STEP_CLEANUP,
	STEP_FINISH,
	STEP_DONE
};

//the five headline tests reported in the results file
const char *TEST_MAINMENU_SHOT = "MAINMENU_SCREENSHOT";
const char *TEST_BROWSER_INSTALL = "BROWSER_DMOD_INSTALL";
const char *TEST_URL_INSTALL = "URL_DMOD_INSTALL";
const char *TEST_NEWGAME_SHOT = "NEWGAME_SCREENSHOT";
const char *TEST_CLEANUP = "CLEANUP";

static bool s_bActive = false;
static eAutoTestStep s_step = STEP_INACTIVE;
static unsigned int s_stepStartMS = 0;
static unsigned int s_condMetMS = 0;      //when the current step's condition was first seen true, 0 if not yet
static unsigned int s_testStartMS = 0;    //for the global watchdog
static bool s_bStepEntryDone = false;

static string s_outDir;
static string s_pendingScreenshotFile;
static string s_screenshotError;

static int s_testsPassed = 0;
static int s_testsFailed = 0;

//cleanup bookkeeping
static vector<string> s_baselineDmodDirs;
static vector<string> s_installedDmodDirs; //dirs we created, to delete in cleanup
static bool s_bContinueStateExistedAtStart = false;
static bool s_bRenamedStateDat = false;
static string s_savedLastPath;

//per-attempt scratch
static string s_browserDmodURL;
static float s_browserDmodSize = 0;
static eAutoTestStep s_afterRecoverStep = STEP_CLEANUP;

const unsigned int TIMEOUT_DEFAULT_MS = 30000;
const unsigned int TIMEOUT_DOWNLOAD_MS = 180000;
const unsigned int TIMEOUT_WATCHDOG_MS = 10 * 60 * 1000;

bool AutoTesterIsActive()
{
	return s_bActive;
}

static string GetResultsFileName()
{
	return s_outDir + "autotest_results.txt";
}

static void AppendToResults(const string &line)
{
	LogMsg("AUTOTEST: %s", line.c_str());
	FILE *fp = fopen(GetResultsFileName().c_str(), "a");
	if (!fp) return;
	fprintf(fp, "%s\n", line.c_str());
	fclose(fp);
}

static void RecordTestResult(const string &testName, bool bPass, const string &detail)
{
	string line = "RESULT: " + testName + (bPass ? " PASS" : " FAIL");
	if (!detail.empty()) line += " (" + detail + ")";
	AppendToResults(line);
	if (bPass) s_testsPassed++; else s_testsFailed++;
}

static void SetStep(eAutoTestStep step)
{
	s_step = step;
	s_stepStartMS = GetTick();
	s_condMetMS = 0;
	s_bStepEntryDone = false;
}

static Entity * GetGUIRoot()
{
	return GetEntityRoot()->GetEntityByName("GUI");
}

static Entity * FindMenu(const string &name)
{
	return GetEntityRoot()->GetEntityByName(name);
}

static bool MainMenuIsReady()
{
	Entity *pMenu = FindMenu("MainMenu");
	if (!pMenu) return false;
	return pMenu->GetEntityByName("New") != NULL;
}

static void FireButton(Entity *pButton)
{
	VariantList v(CL_Vec2f(0, 0), pButton);
	pButton->GetFunction("OnButtonSelected")->sig_function(&v);
}

//returns "" if not found
static string GetInstallMenuTitleText()
{
	Entity *pMenu = FindMenu("DMODInstall");
	if (!pMenu) return "";
	Entity *pLabel = pMenu->GetEntityByName("title_label");
	if (!pLabel) return "";
	EntityComponent *pText = pLabel->GetComponentByName("TextRender");
	if (!pText) return "";
	return pText->GetVar("text")->GetString();
}

static int GetFileSizeBytes(const string &fName)
{
	FILE *fp = fopen(fName.c_str(), "rb");
	if (!fp) return 0;
	fseek(fp, 0, SEEK_END);
	int size = (int)ftell(fp);
	fclose(fp);
	return size;
}

//returns the first dir in the dmod root that isn't in our baseline snapshot and looks like a
//finished DMOD install (has dmod.diz), or "" if none yet
static string FindNewDmodDir()
{
	vector<string> dirs = GetDirectoriesAtPath(GetDMODRootPath());
	for (unsigned int i = 0; i < dirs.size(); i++)
	{
		bool bInBaseline = false;
		for (unsigned int j = 0; j < s_baselineDmodDirs.size(); j++)
		{
			if (dirs[i] == s_baselineDmodDirs[j]) { bInBaseline = true; break; }
		}
		if (bInBaseline) continue;

		bool bAlreadyRecorded = false;
		for (unsigned int j = 0; j < s_installedDmodDirs.size(); j++)
		{
			if (dirs[i] == s_installedDmodDirs[j]) { bAlreadyRecorded = true; break; }
		}
		if (bAlreadyRecorded) continue;

		if (FileExists(GetDMODRootPath() + dirs[i] + "/dmod.diz"))
		{
			return dirs[i];
		}
	}
	return "";
}

//kill any menus we might be stuck in and get back to a fresh main menu, then continue at afterStep
static void StartRecovery(eAutoTestStep afterStep)
{
	s_afterRecoverStep = afterStep;

	if (GetDinkGameState() == DINK_GAME_STATE_PLAYING && FindMenu("GameMenu"))
	{
		DinkQuitGame(); //also recreates the right menu itself
		SetStep(STEP_RECOVER);
		return;
	}

	const char *menusToKill[] = { "DMODInstall", "BrowseMenu", "DMODMenu", "MainMenu" };
	bool bKilledSomething = false;
	for (unsigned int i = 0; i < sizeof(menusToKill) / sizeof(menusToKill[0]); i++)
	{
		Entity *pMenu = FindMenu(menusToKill[i]);
		if (pMenu)
		{
			pMenu->SetName(string(menusToKill[i]) + "Delete");
			GetMessageManager()->CallEntityFunction(pMenu, 1, "OnDelete", NULL);
			bKilledSomething = true;
		}
	}

	(void)bKilledSomething;
	SetStep(STEP_RECOVER);
}

static void DoCleanup()
{
	bool bCleanupOK = true;
	string detail;

	for (unsigned int i = 0; i < s_installedDmodDirs.size(); i++)
	{
		string path = GetDMODRootPath() + s_installedDmodDirs[i];
		RemoveDirectoryRecursively(path);
		if (FileExists(path + "/dmod.diz"))
		{
			bCleanupOK = false;
			detail += "couldn't delete " + path + " ";
		}
	}

	RemoveFile(GetDMODRootPath() + "temp.dmod", false);

	if (s_bRenamedStateDat)
	{
		rename((GetSavePath() + "state.dat.autotest_bak").c_str(), (GetSavePath() + "state.dat").c_str());
	}

	WriteLastPathSaved(s_savedLastPath);

	if (!s_bContinueStateExistedAtStart && FileExists(GetSavePath() + "dink/continue_state.dat"))
	{
		RemoveFile(GetSavePath() + "dink/continue_state.dat", false);
	}

	if (detail.empty()) detail = toString((int)s_installedDmodDirs.size()) + " test dmod(s) removed";
	RecordTestResult(TEST_CLEANUP, bCleanupOK, detail);
}

void AutoTesterInit()
{
	s_bActive = true;
	s_testStartMS = GetTick();

	s_outDir = GetSavePath() + "autotest/";
	CreateDirectoryRecursively(GetSavePath(), "autotest");

	RemoveFile(s_outDir + "autotest_mainmenu.png", false);
	RemoveFile(s_outDir + "autotest_newgame.png", false);
	RemoveFile(GetResultsFileName(), false);

	AppendToResults("AUTOTEST_VERSION: 1");
	AppendToResults("PLATFORM: " + PlatformIDAsString(GetEmulatedPlatformID()));
	AppendToResults("APP_VERSION: " + GetApp()->GetVersionString());

	//neutralize the main menu's startup interceptors, non-destructively

	if (FileExists(GetSavePath() + "state.dat"))
	{
		//the "Continue your last session?" popup would block us (and its Cancel deletes the file!)
		RemoveFile(GetSavePath() + "state.dat.autotest_bak", false);
		if (rename((GetSavePath() + "state.dat").c_str(), (GetSavePath() + "state.dat.autotest_bak").c_str()) == 0)
		{
			s_bRenamedStateDat = true;
		}
	}

	s_savedLastPath = ReadLastPathSaved();
	WriteLastPathSaved("");

	bool bIsCommandLineInstall = false;
	if (!GetNextDMODToInstall(bIsCommandLineInstall, false).empty())
	{
		//a stray .dmod (file or parm) would hijack the main menu with an install we didn't script
		AppendToResults("ABORT: a .dmod install is already pending (stray file or command line parm), can't test");
		AppendToResults("SUMMARY: FAIL (0/5)");
		SetStep(STEP_DONE);
		GetApp()->OnExitApp(NULL);
		return;
	}

	s_bContinueStateExistedAtStart = FileExists(GetSavePath() + "dink/continue_state.dat");
	s_baselineDmodDirs = GetDirectoriesAtPath(GetDMODRootPath());

	LogMsg("AUTOTEST: starting, output dir is %s", s_outDir.c_str());
	SetStep(STEP_WAIT_MAINMENU);
}

void AutoTesterOnPostDraw()
{
	if (s_pendingScreenshotFile.empty()) return;

	int width = GetPrimaryGLX();
	int height = GetPrimaryGLY();

	SoftSurface s;
	if (!s.Init(width, height, SoftSurface::SURFACE_RGBA))
	{
		s_screenshotError = "low mem creating surface";
		s_pendingScreenshotFile.clear();
		return;
	}

	s.BlitFromScreenFixed(0, 0, 0, 0, width, height);

	//framebuffer alpha is undefined, force opaque or the png can render fully transparent
	uint8 *pPixels = s.GetPixelData();
	for (int i = 0; i < width * height; i++)
	{
		pPixels[i * 4 + 3] = 255;
	}

	s.FlipY(); //glReadPixels gives us bottom-up rows, png wants top-down
	s.WritePNGOut(s_pendingScreenshotFile, 6);
	LogMsg("AUTOTEST: wrote %s (%dx%d)", s_pendingScreenshotFile.c_str(), width, height);
	s_pendingScreenshotFile.clear();
}

//shared logic for the three screenshot-ish wait steps that need a dwell after their condition hits
static bool ConditionHeldFor(bool bCondition, unsigned int dwellMS)
{
	if (!bCondition)
	{
		s_condMetMS = 0;
		return false;
	}
	if (s_condMetMS == 0) s_condMetMS = GetTick();
	return GetTick() >= s_condMetMS + dwellMS;
}

static bool StepTimedOut(unsigned int timeoutMS)
{
	return GetTick() >= s_stepStartMS + timeoutMS;
}

void AutoTesterUpdate()
{
	if (!s_bActive || s_step == STEP_INACTIVE || s_step == STEP_DONE) return;

	//global watchdog: whatever happens, a run may never hang forever
	if (s_step < STEP_CLEANUP && GetTick() > s_testStartMS + TIMEOUT_WATCHDOG_MS)
	{
		AppendToResults("WATCHDOG: total time limit hit, jumping to cleanup");
		SetStep(STEP_CLEANUP);
		return;
	}

	switch (s_step)
	{

	case STEP_WAIT_MAINMENU:

		if (ConditionHeldFor(MainMenuIsReady(), 3000)) //3 secs so the dink logo finishes its slide, prettier screenshot
		{
			SetStep(STEP_SHOT_MAINMENU);
			break;
		}
		if (StepTimedOut(TIMEOUT_DEFAULT_MS))
		{
			RecordTestResult(TEST_MAINMENU_SHOT, false, "timed out waiting for main menu");
			StartRecovery(STEP_WAIT_MAINMENU_2); //skip ahead to the URL test path... browser needs main menu too though
			//actually if the main menu never showed, the browser test can't run either
			RecordTestResult(TEST_BROWSER_INSTALL, false, "main menu never appeared");
		}
		break;

	case STEP_SHOT_MAINMENU:

		if (!s_bStepEntryDone)
		{
			s_bStepEntryDone = true;
			s_screenshotError.clear();
			s_pendingScreenshotFile = s_outDir + "autotest_mainmenu.png";
		}

		if (s_pendingScreenshotFile.empty())
		{
			string f = s_outDir + "autotest_mainmenu.png";
			bool bOK = s_screenshotError.empty() && GetFileSizeBytes(f) > 0;
			RecordTestResult(TEST_MAINMENU_SHOT, bOK, bOK ? f : s_screenshotError);
			SetStep(STEP_OPEN_DMOD_MENU);
			break;
		}

		if (StepTimedOut(5000))
		{
			RecordTestResult(TEST_MAINMENU_SHOT, false, "screenshot never got written");
			s_pendingScreenshotFile.clear();
			SetStep(STEP_OPEN_DMOD_MENU);
		}
		break;

	case STEP_OPEN_DMOD_MENU:

		if (!s_bStepEntryDone)
		{
			s_bStepEntryDone = true;
			Entity *pMenu = FindMenu("MainMenu");
			Entity *pBtn = pMenu ? pMenu->GetEntityByName("Add-ons") : NULL;
			if (!pBtn)
			{
				RecordTestResult(TEST_BROWSER_INSTALL, false, "no Add-ons button on main menu");
				StartRecovery(STEP_WAIT_MAINMENU_2);
				break;
			}
			FireButton(pBtn);
		}

		if (ConditionHeldFor(FindMenu("DMODMenu") != NULL, 800))
		{
			SetStep(STEP_OPEN_BROWSER);
			break;
		}
		if (StepTimedOut(TIMEOUT_DEFAULT_MS))
		{
			RecordTestResult(TEST_BROWSER_INSTALL, false, "DMOD menu never appeared");
			StartRecovery(STEP_WAIT_MAINMENU_2);
		}
		break;

	case STEP_OPEN_BROWSER:

		if (!s_bStepEntryDone)
		{
			s_bStepEntryDone = true;
			Entity *pMenu = FindMenu("DMODMenu");
			Entity *pBtn = pMenu ? pMenu->GetEntityByName("browse") : NULL;
			if (!pBtn)
			{
				RecordTestResult(TEST_BROWSER_INSTALL, false, "no browse button (DMOD downloads disabled?)");
				StartRecovery(STEP_WAIT_MAINMENU_2);
				break;
			}
			FireButton(pBtn);
		}

		//wait for the live list to be downloaded and parsed
		if (FindMenu("BrowseMenu") && BrowseMenuGetDMODCount() > 0)
		{
			SetStep(STEP_START_BROWSER_INSTALL);
			break;
		}
		if (StepTimedOut(60000))
		{
			RecordTestResult(TEST_BROWSER_INSTALL, false, "dmod list never downloaded from dinknetwork.com");
			StartRecovery(STEP_WAIT_MAINMENU_2);
		}
		break;

	case STEP_START_BROWSER_INSTALL:
	{
		if (!BrowseMenuGetDMODInfoByName(AUTOTEST_BROWSER_DMOD_NAME, s_browserDmodURL, s_browserDmodSize))
		{
			RecordTestResult(TEST_BROWSER_INSTALL, false, "'" + AUTOTEST_BROWSER_DMOD_NAME + "' not found in the live list");
			StartRecovery(STEP_WAIT_MAINMENU_2);
			break;
		}

		//replicate what clicking a bar's install icon does (BrowseMenuOnSelect)
		Entity *pMenu = FindMenu("BrowseMenu");
		Entity *pParent = pMenu->GetParent();
		DisableAllButtonsEntity(pMenu);
		SlideScreen(pMenu, false);
		GetMessageManager()->CallEntityFunction(pMenu, 500, "OnDelete", NULL);
		DMODInstallMenuCreate(pParent, s_browserDmodURL, GetDMODRootPath(), "", true, AUTOTEST_BROWSER_DMOD_NAME, true, s_browserDmodSize);
		SetStep(STEP_WAIT_BROWSER_INSTALL);
		break;
	}

	case STEP_WAIT_BROWSER_INSTALL:
	case STEP_WAIT_URL_INSTALL:
	{
		const char *testName = (s_step == STEP_WAIT_BROWSER_INSTALL) ? TEST_BROWSER_INSTALL : TEST_URL_INSTALL;
		eAutoTestStep dismissStep = (s_step == STEP_WAIT_BROWSER_INSTALL) ? STEP_DISMISS_INSTALL_1 : STEP_DISMISS_INSTALL_2;
		eAutoTestStep failContinueStep = (s_step == STEP_WAIT_BROWSER_INSTALL) ? STEP_WAIT_MAINMENU_2 : STEP_WAIT_MAINMENU_3;

		string title = GetInstallMenuTitleText();

		if (IsInString(title, "successfully"))
		{
			//the unpacker is done; verify a new valid dmod dir actually exists
			string newDir = FindNewDmodDir();
			if (!newDir.empty())
			{
				s_installedDmodDirs.push_back(newDir);
				RecordTestResult(testName, true, "dir=" + newDir);
			}
			else
			{
				RecordTestResult(testName, false, "install claimed success but no new dmod dir found");
			}
			SetStep(dismissStep);
			break;
		}

		if (IsInString(title, "Error!"))
		{
			Entity *pMenu = FindMenu("DMODInstall");
			Entity *pStatus = pMenu ? pMenu->GetEntityByName("status") : NULL;
			string statusText;
			if (pStatus && pStatus->GetComponentByName("TextRender"))
			{
				statusText = pStatus->GetComponentByName("TextRender")->GetVar("text")->GetString();
			}
			RecordTestResult(testName, false, "installer error: " + statusText);
			SetStep(dismissStep); //still need to dismiss the menu
			break;
		}

		if (StepTimedOut(TIMEOUT_DOWNLOAD_MS))
		{
			RecordTestResult(testName, false, "download/unpack timed out");
			StartRecovery(failContinueStep);
		}
		break;
	}

	case STEP_DISMISS_INSTALL_1:
	case STEP_DISMISS_INSTALL_2:
	{
		//don't click "Back": on success it's "Play it now" and would launch the DMOD.
		//kill the menu the same way the real handlers do, then bring the main menu back.
		Entity *pMenu = FindMenu("DMODInstall");
		if (pMenu)
		{
			Entity *pParent = pMenu->GetParent();
			SlideScreen(pMenu, false);
			pMenu->SetName("DMODInstallDelete");
			GetMessageManager()->CallEntityFunction(pMenu, 500, "OnDelete", NULL);
			MainMenuCreate(pParent);
		}
		else
		{
			MainMenuCreate(GetGUIRoot());
		}
		SetStep(s_step == STEP_DISMISS_INSTALL_1 ? STEP_WAIT_MAINMENU_2 : STEP_WAIT_MAINMENU_3);
		break;
	}

	case STEP_WAIT_MAINMENU_2:
	case STEP_WAIT_MAINMENU_3:
	case STEP_RECOVER:
	{
		eAutoTestStep nextStep;
		if (s_step == STEP_WAIT_MAINMENU_2) nextStep = STEP_START_URL_INSTALL;
		else if (s_step == STEP_WAIT_MAINMENU_3) nextStep = STEP_START_NEWGAME;
		else nextStep = s_afterRecoverStep;

		if (s_step == STEP_RECOVER && !s_bStepEntryDone)
		{
			//give killed menus a moment to actually die, then create a fresh main menu if none exists
			if (GetTick() < s_stepStartMS + 1200) break;
			s_bStepEntryDone = true;
			if (!FindMenu("MainMenu"))
			{
				MainMenuCreate(GetGUIRoot());
			}
		}

		if (ConditionHeldFor(MainMenuIsReady(), 1000))
		{
			SetStep(nextStep);
			break;
		}
		if (StepTimedOut(TIMEOUT_DEFAULT_MS))
		{
			//can't get back to a working main menu; skip whatever tests remain
			if (nextStep <= STEP_START_URL_INSTALL) RecordTestResult(TEST_URL_INSTALL, false, "no main menu to start from");
			if (nextStep <= STEP_START_NEWGAME) RecordTestResult(TEST_NEWGAME_SHOT, false, "no main menu to start from");
			SetStep(STEP_CLEANUP);
		}
		break;
	}

	case STEP_START_URL_INSTALL:
	{
		//same thing EnterURLMenu's continue button does, minus typing the url
		Entity *pMenu = FindMenu("MainMenu");
		Entity *pParent = pMenu->GetParent();
		DisableAllButtonsEntity(pMenu);
		SlideScreen(pMenu, false);
		pMenu->SetName("MainMenuDelete");
		GetMessageManager()->CallEntityFunction(pMenu, 500, "OnDelete", NULL);
		DMODInstallMenuCreate(pParent, AUTOTEST_URL_DMOD_URL, GetDMODRootPath());
		SetStep(STEP_WAIT_URL_INSTALL);
		break;
	}

	case STEP_START_NEWGAME:

		if (!s_bStepEntryDone)
		{
			s_bStepEntryDone = true;
			Entity *pMenu = FindMenu("MainMenu");
			Entity *pBtn = pMenu ? pMenu->GetEntityByName("New") : NULL;
			if (!pBtn)
			{
				RecordTestResult(TEST_NEWGAME_SHOT, false, "no New button on main menu");
				SetStep(STEP_CLEANUP);
				break;
			}
			FireButton(pBtn);
		}
		SetStep(STEP_WAIT_NEWGAME);
		break;

	case STEP_WAIT_NEWGAME:

		if (GetDinkGameState() == DINK_GAME_STATE_PLAYING && g_dglo.m_curLoadState == FINISHED_LOADING)
		{
			SetStep(STEP_SHOT_NEWGAME);
			break;
		}
		if (StepTimedOut(60000))
		{
			RecordTestResult(TEST_NEWGAME_SHOT, false, "game never reached playing state");
			StartRecovery(STEP_CLEANUP);
		}
		break;

	case STEP_SHOT_NEWGAME:

		if (!s_bStepEntryDone)
		{
			//let the intro render something representative first
			if (GetTick() < s_stepStartMS + 5000) break;
			s_bStepEntryDone = true;
			s_screenshotError.clear();
			s_pendingScreenshotFile = s_outDir + "autotest_newgame.png";
			break;
		}

		if (s_pendingScreenshotFile.empty())
		{
			string f = s_outDir + "autotest_newgame.png";
			bool bOK = s_screenshotError.empty() && GetFileSizeBytes(f) > 0;
			RecordTestResult(TEST_NEWGAME_SHOT, bOK, bOK ? f : s_screenshotError);
			SetStep(STEP_QUIT_GAME);
			break;
		}

		if (StepTimedOut(TIMEOUT_DEFAULT_MS))
		{
			RecordTestResult(TEST_NEWGAME_SHOT, false, "screenshot never got written");
			s_pendingScreenshotFile.clear();
			SetStep(STEP_QUIT_GAME);
		}
		break;

	case STEP_QUIT_GAME:

		if (!s_bStepEntryDone)
		{
			s_bStepEntryDone = true;
			if (GetDinkGameState() == DINK_GAME_STATE_PLAYING)
			{
				//exits to the menu WITHOUT writing continue_state.dat (unlike the pause menu's Quit)
				DinkQuitGame();
			}
		}

		if (ConditionHeldFor(MainMenuIsReady(), 1000))
		{
			SetStep(STEP_CLEANUP);
			break;
		}
		if (StepTimedOut(20000))
		{
			SetStep(STEP_CLEANUP); //cleanup doesn't need the menu anyway
		}
		break;

	case STEP_CLEANUP:

		DoCleanup();
		SetStep(STEP_FINISH);
		break;

	case STEP_FINISH:
	{
		char summary[128];
		sprintf(summary, "SUMMARY: %s (%d/%d)", (s_testsFailed == 0) ? "PASS" : "FAIL", s_testsPassed, s_testsPassed + s_testsFailed);
		AppendToResults(summary);
		SetStep(STEP_DONE);
		GetApp()->OnExitApp(NULL);
		break;
	}

	default:
		break;
	}
}
