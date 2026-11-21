/*----------------------------------------------------------
OpenKey - The Cross platform Open source Vietnamese Keyboard application.

Copyright (C) 2019 360 CORP & VUA HỆ THỐNG
Contact: support@360.org.vn
Github: https://github.com/360org/MacVietKey
Fanpage: https://www.facebook.com/OpenKeyVN

This file is belong to the OpenKey project, Win32 version
which is released under GPL license.
You can fork, modify, improve this program. If you
redistribute your new version, it MUST be open source.
-----------------------------------------------------------*/
#pragma once
#include "BaseDialog.h"

class MacroDialog :	public BaseDialog {
private:
	HWND listMacro;
	HWND hMacroName, hMacroContent;
	HWND hAddButton, hAutoCaps;
	vector<vector<Uint32>> keys;
	vector<string> macroText;
	vector<string> macroContent;
public:
	MacroDialog(const HINSTANCE & hInstance, const int & resourceId);
	~MacroDialog();
	virtual void fillData() override;
protected:
	INT_PTR eventProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam);
	void initDialog();
private:
	void saveAndReload();
	void insertItem(const int& index, LPTSTR macroName, LPTSTR macroContent);

	void onSelectItem(const int& index);
	void onAddMacroButton();
	void onDeleteMacroButton();

	void onImportMacroButton();
	void onExportMacrobutton();

	void onCheckboxClicked(const HWND& hWnd);
};

