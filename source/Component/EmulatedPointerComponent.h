//  ***************************************************************
//  EmulatedPointerComponent - Creation date: 12/08/2022
//  -------------------------------------------------------------
//  Robinson Technologies Copyright (C) 2022 - All Rights Reserved
//
//  ***************************************************************
//  Programmer(s):  Seth A. Robinson (seth@rtsoft.com)
//  ***************************************************************

#ifndef EmulatedPointerComponent_h__
#define EmulatedPointerComponent_h__

#include "Entity/Component.h"
#include "Entity/Entity.h"
#include "../dink/dink.h"

class ArcadeInputComponent;

class EmulatedPointerComponent : public EntityComponent
{
public:
	EmulatedPointerComponent();
	virtual ~EmulatedPointerComponent();

	virtual void OnAdd(Entity* pEnt);
	virtual void OnRemove();

	bool ShouldShow();
	
private:

	void OnRender(VariantList* pVList);
	void SetShouldShow(bool bNew);
	void ResetPointerWasMovedTimer();
	void OnUpdate(VariantList* pVList);
	void OnArcadeInput(VariantList* pVList);
	void OnGamepadButton(VariantList* pVList);
	
	CL_Vec2f* m_pPos2d;
	

	bool m_bButtonDown = false;
	bool m_bSpeedButton = false;
	bool m_bCurrentlyShowing = false;
	Entity *m_pPointerOverlay = NULL;
	ArcadeInputComponent* m_pArcade = NULL;
	unsigned int m_inputTimerMS =0;
};

#endif // EmulatedPointerComponent_h__