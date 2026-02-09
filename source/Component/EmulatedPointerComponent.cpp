#include "PlatformPrecomp.h"
#include "EmulatedPointerComponent.h"
#include "util/GLESUtils.h"
#include "Entity/EntityUtils.h"
#include "BaseApp.h"
#include "Entity/ArcadeInputComponent.h"

const unsigned int C_TIME_TO_SHOW_POINTER_AFTER_MOVING_IT_MS = 5000;


void SendFakeInputMessageToAll(eMessageType msg, CL_Vec2f vClickPos)
{
	GetMessageManager()->SendGUIEx2((eMessageType)msg, vClickPos.x, vClickPos.y, 1, 0);
}

EmulatedPointerComponent::EmulatedPointerComponent()
{
	SetName("EmulatedPointer");
}

EmulatedPointerComponent::~EmulatedPointerComponent()
{
}

void EmulatedPointerComponent::OnAdd(Entity* pEnt)
{
	EntityComponent::OnAdd(pEnt);
	m_pPos2d = &GetParent()->GetVar("pos2d")->GetVector2();

	m_pArcade = (ArcadeInputComponent*)GetEntityRoot()->GetComponentByName("ArcadeInput");

	
	//register ourselves to render if the parent does
	//GetParent()->GetFunction("OnRender")->sig_function.connect(1, boost::bind(&EmulatedPointerComponent::OnRender, this, _1));
	GetParent()->GetFunction("OnUpdate")->sig_function.connect(1, boost::bind(&EmulatedPointerComponent::OnUpdate, this, _1));
	LogMsg("Added emulated pointer");
	
	//set an image for our pointer
	string pointerImage;
	pointerImage = "interface/center_ball.rttex";
	
	m_pPointerOverlay = CreateOverlayEntity(GetParent(), "EmPointer", pointerImage, 0, 0, true);
	SetAlignmentEntity(m_pPointerOverlay, ALIGNMENT_UPPER_LEFT);
	SetAlphaEntity(m_pPointerOverlay, 0);
	//get notified of joystick buttons
	GetBaseApp()->m_sig_arcade_input.connect(1, boost::bind(&EmulatedPointerComponent::OnArcadeInput, this, _1));
	
}

//doing it this way let's us handle both keyboard and gamepad messages together, however ArcadeInput was mapped

void EmulatedPointerComponent::OnArcadeInput(VariantList* pVList)
{
	if (!ShouldShow()) return;

	int vKey = pVList->Get(0).GetUINT32();
	bool bIsDown = pVList->Get(1).GetUINT32() != 0;

	//LogMsg("Key %d, down is %d", vKey, int(bIsDown));
	
	CL_Vec2f vPos = *m_pPos2d;
	
	switch (vKey)
	{
	case 9: //this works because ArcadeInput has mapped right shoulder button to tab already
		m_bSpeedButton = bIsDown;
	break;

	case VIRTUAL_KEY_GAME_FIRE:
		
		ResetPointerWasMovedTimer();

		if (bIsDown)
		{
			m_bButtonDown = true;
			SendFakeInputMessageToAll(MESSAGE_TYPE_GUI_CLICK_START, vPos);
		}
		else
		{
			m_bButtonDown = false;
			SendFakeInputMessageToAll(MESSAGE_TYPE_GUI_CLICK_END, vPos);
		}

		break;

	default:;
	}
}

void EmulatedPointerComponent::OnRemove()
{
	EntityComponent::OnRemove();
}

bool EmulatedPointerComponent::ShouldShow()
{
	return m_bCurrentlyShowing;
	
}


void EmulatedPointerComponent::SetShouldShow(bool bNew)
{
	if (bNew == m_bCurrentlyShowing) return; //no change, who cares

	//ok, status changed

	if (bNew)
	{
		//it's become visible
		FadeInEntity(m_pPointerOverlay, false, 100);
		*m_pPos2d = CL_Vec2f(GetScreenSizeXf() / 2, GetScreenSizeYf() / 2);
	}
	else
	{
		//hide it
		FadeOutEntity(m_pPointerOverlay, false, 100);
	}

	m_bCurrentlyShowing = bNew;
}


void EmulatedPointerComponent::ResetPointerWasMovedTimer()
{
	m_inputTimerMS = GetSystemTimeTick() + C_TIME_TO_SHOW_POINTER_AFTER_MOVING_IT_MS;
}

//process gamepad or keyboard movement
void EmulatedPointerComponent::OnUpdate(VariantList* pVList)
{
	
	if (GetDinkGameState() == DINK_GAME_STATE_PLAYING && GetBaseApp()->GetGameTickPause() == false)
	{
		SetShouldShow(false);
		return;
	}


		
	float speed = 8;
	if (m_bSpeedButton) speed *= 3;

	if (m_pArcade)
	{
		CL_Vec2f vDir = CL_Vec2f(0, 0);
		CL_Vec2f vPos = *m_pPos2d;

		if (m_pArcade->GetDirectionKeysAsVector(&vDir))
		{

			ResetPointerWasMovedTimer();
			//LogMsg("Dir: %s", PrintVector2(vDir).c_str());
			(*m_pPos2d) += (vDir * speed);

			//clip to screen
			ForceRange(m_pPos2d->x, 0, GetScreenSizeXf());
			ForceRange(m_pPos2d->y, 0, GetScreenSizeYf());
			
			if (m_bButtonDown)
			{
				SendFakeInputMessageToAll(MESSAGE_TYPE_GUI_CLICK_MOVE, vPos);
			}
		}
	}


	if (m_inputTimerMS >= GetSystemTimeTick())
	{
		SetShouldShow(true);
	}
	else
	{
		SetShouldShow(false);
	}
}

