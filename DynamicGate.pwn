#include <a_samp>
#include <utils>
#pragma unused ReturnUser
#include <a_mysql>
#include <YSI\y_iterate>
#include <easydialog>
#include <zcmd>
#include <streamer>

/*
			dynamisches Torsystem
			-   Erstellen   -
			-   Löschen     -
			-   Editieren   -
			_____________________
			    22.11.2018
			by: DominikGLL
			
			Speicherung
			    - MySQL

			(Erweiterbar)
			
			Includes:
			    - utils (by ?)
			    - MySQL (by BlueG)
			    - YSI / Iterate (old: foreach) (by Y_Less)
				- EasyDialog (by Emmet_)
				- ZCMD (by Zeex)
				- Streamer (by Incognito)

*/


#define MAX_GATES   		5

enum GateEnum {
	DatabaseID,
	GateName[32],
	GateModel,
	bool:GateLocked,
	GateObject,
	Float:GateOpen[6],
	Float:GateClose[6]
}
new GateInfo[MAX_GATES][GateEnum],
	Iterator:Gates<MAX_GATES>,
	MySQL:handler;
	
COMMAND:tor(playerid, params[]){
    if(!Iter_Count(Gates))return SendClientMessage(playerid, -1, "{FF0000}FEHLER: {FFFFFF}Es wurden keine dynamischen Tore erstellt.");
	new Float:x, Float:y, Float:z, string[144];
	foreach(new i:Gates) {
		 GetDynamicObjectPos(GateInfo[i][GateObject], x, y, z);
		 if(!IsPlayerInRangeOfPoint(playerid, 5.0, x, y, z))continue;
		 format(string, sizeof(string),"{3399FF}INFO: {FFFFFF}Du hast die Funkfernbedinung für das Tor %s (%i) betätigt und es wird %s",
		 GateInfo[i][GateName], i, ((GateInfo[i][GateLocked])?("geöffnet"):("geschlossen")));
		 SendClientMessage(playerid, -1, string);
		 return ((GateInfo[i][GateLocked]) ? (MoveDynamicObject(GateInfo[i][GateObject], GateInfo[i][GateOpen][0], GateInfo[i][GateOpen][1], GateInfo[i][GateOpen][2], 5000, GateInfo[i][GateOpen][3], GateInfo[i][GateOpen][4], GateInfo[i][GateOpen][5])) :
		        (MoveDynamicObject(GateInfo[i][GateObject], GateInfo[i][GateClose][0], GateInfo[i][GateClose][1], GateInfo[i][GateClose][2], 5000, GateInfo[i][GateClose][3], GateInfo[i][GateClose][4], GateInfo[i][GateClose][5])));
	}
	return 1;
}

COMMAND:creategate(playerid, params[]) {
	if(isnull(params))return SendClientMessage(playerid, -1,"{FF0000}FEHLER: {FFFFFF}/creategate [GateID]");
	if(!IsNumeric(params))return SendClientMessage(playerid, -1,"{FF0000}FEHLER: {FFFFFF}/creategate [GateID]");
	new
	    slot = Iter_Free(Gates), string[144];
	if(slot == -1)return SendClientMessage(playerid, -1, "{FF0000}FEHLER: {FFFFFF}Es wurde bereits die maximale Anzahl an dynamischen Toren erstellt.");
	Iter_Add(Gates, slot);
	SetPVarInt(playerid, "Create:Gate:id", slot);
	SetPVarInt(playerid, "Create:Gate:step", 1);
	GetPlayerPos(playerid, GateInfo[slot][GateClose][0], GateInfo[slot][GateClose][1], GateInfo[slot][GateClose][2]);
 	format(GateInfo[slot][GateName], 32, "DynTor");
	GateInfo[slot][GateObject] = CreateDynamicObject(strval(params),GateInfo[slot][GateClose][0], GateInfo[slot][GateClose][1], GateInfo[slot][GateClose][2], 0.00, 0.00, 0.00);
	EditDynamicObject(playerid, GateInfo[slot][GateObject]);
 	GateInfo[slot][GateModel] = strval(params);
 	GateInfo[slot][GateClose][3] = 0.00, GateInfo[slot][GateClose][4] = 0.00, GateInfo[slot][GateClose][5] = 0.00;
 	mysql_format(handler, string, sizeof(string),"INSERT INTO `gates` (`gatename`, `gatemodel`, `close:x`, `close:y`, `close:z`, `close:rx`, `close:ry`, `close:rz`) VALUES ('%s', '%i', '%f', '%f', '%f', '%f', '%f', '%f')",
 	GateInfo[slot][GateName], strval(params), GateInfo[slot][GateClose][0], GateInfo[slot][GateClose][1], GateInfo[slot][GateClose][2], 0.00, 0.00, 0.00);
	mysql_pquery(handler, string, "InsertGate", "i", slot);
	format(string, sizeof(string),"{3399FF}INFO: {FFFFFF}Du hast mit der Erstellung eines dynamischen Tores (%i) begonnen. Platziere das Tor nun bei geschlossenem Zustand.",slot);
	return SendClientMessage(playerid, -1, string);
}

COMMAND:editgate(playerid, params[]) {
    if(!Iter_Count(Gates))return SendClientMessage(playerid, -1, "{FF0000}FEHLER: {FFFFFF}Es wurden keine dynamischen Tore erstellt.");
	new Float:x, Float:y, Float:z, string[144];
	foreach(new i:Gates) {
		 GetDynamicObjectPos(GateInfo[i][GateObject], x, y, z);
		 if(!IsPlayerInRangeOfPoint(playerid, 5.0, x, y, z))continue;
		 SetPVarInt(playerid, "Edit:Gate:id", i);
		 SetPVarInt(playerid, "Edit:Gate:marker", CreateDynamicCP(x, y, z, 5.0));
		 format(string, sizeof(string),"Name: %s\nObjekt: %i\nGeschlossene Position\nGeöffnete Position",
		 GateInfo[i][GateName], GateInfo[i][GateModel]);
		 return Dialog_Show(playerid, GateEditMenu, DIALOG_STYLE_LIST, "Dynamisches Tor: Editieren", string, "Auswählen", "Abbrechen");
	}
	return 1;
}

Dialog:GateEditMenu(playerid, response, listitem, inputtext[]) {
    if(!response) {
	    DestroyDynamicCP(GetPVarInt(playerid, "Edit:Gate:marker"));
	    DeletePVar(playerid, "Edit:Gate:id");
	    DeletePVar(playerid, "Edit:Gate:marker");
		return 1;
	}
	switch(listitem) {
		case 0: return Dialog_Show(playerid, GateEditName, DIALOG_STYLE_INPUT, "Dynamisches Tor: Name editieren", "Gib den gewünschten Tornamen ein\n(maximal 32 Zeichen)", "Bestätigen", "Abbrechen");
		case 1: return Dialog_Show(playerid, GateEditObj, DIALOG_STYLE_INPUT, "Dynamisches Tor: Objekt editieren", "Gib die gewünschte Objekt ID ein.", "Bestätigen", "Abbrechen");
		case 2: {
		    new
		        slot = GetPVarInt(playerid, "Edit:Gate:id");
		    DestroyDynamicCP(GetPVarInt(playerid, "Edit:Gate:marker"));
		    DeletePVar(playerid, "Edit:Gate:marker");
		    SetPVarInt(playerid, "Edit:Gate:Type", 1);
		    SetDynamicObjectPos(GateInfo[slot][GateObject], GateInfo[slot][GateClose][0], GateInfo[slot][GateClose][1], GateInfo[slot][GateClose][2]);
    		SetDynamicObjectPos(GateInfo[slot][GateObject], GateInfo[slot][GateClose][3], GateInfo[slot][GateClose][4], GateInfo[slot][GateClose][5]);
		    EditDynamicObject(playerid, GateInfo[slot][GateObject]);
		    return SendClientMessage(playerid, -1, "{3399FF}INFO: {FFFFFF}Positioniere nun das Tor für die neue geschlossene Position.");
		}
		case 3: {
		    new
		        slot = GetPVarInt(playerid, "Edit:Gate:id");
		    DestroyDynamicCP(GetPVarInt(playerid, "Edit:Gate:marker"));
		    DeletePVar(playerid, "Edit:Gate:marker");
		    SetPVarInt(playerid, "Edit:Gate:Type", 2);
		    SetDynamicObjectPos(GateInfo[slot][GateObject], GateInfo[slot][GateOpen][0], GateInfo[slot][GateOpen][1], GateInfo[slot][GateOpen][2]);
    		SetDynamicObjectPos(GateInfo[slot][GateObject], GateInfo[slot][GateOpen][3], GateInfo[slot][GateOpen][4], GateInfo[slot][GateOpen][5]);
		    EditDynamicObject(playerid, GateInfo[slot][GateObject]);
		    return SendClientMessage(playerid, -1, "{3399FF}INFO: {FFFFFF}Positioniere nun das Tor für die neue geöffnete Position.");
		}
	}
	return 1;
}

Dialog:GateEditName(playerid, response, listitem, inputtext[]) {
	new
		slot = GetPVarInt(playerid, "Edit:Gate:id"),
		string[144];
    DestroyDynamicCP(GetPVarInt(playerid, "Edit:Gate:marker"));
 	DeletePVar(playerid, "Edit:Gate:id");
 	DeletePVar(playerid, "Edit:Gate:marker");
	if(!response)return 1;
	if(strlen(inputtext) < 0 || strlen(inputtext) > 32)return SendClientMessage(playerid, -1, "{FF0000}FEHLER: {FFFFFF} Es sind maximal 32 Zeichen erlaubt.");
 	format(GateInfo[slot][GateName], 32, "%s", inputtext);
 	SaveServerGates(slot);
	format(string, sizeof(string),"{3399FF}INFO: {FFFFFF}Du hast das Tor (%i) zu %s umbenannt.", slot, inputtext);
	return SendClientMessage(playerid, -1, string);
}

Dialog:GateEditObj(playerid, response, listitem, inputtext[]) {
    new
		slot = GetPVarInt(playerid, "Edit:Gate:id"),
		string[144];
    DestroyDynamicCP(GetPVarInt(playerid, "Edit:Gate:marker"));
 	DeletePVar(playerid, "Edit:Gate:id");
 	DeletePVar(playerid, "Edit:Gate:marker");
    if(!response)return 1;
    if(!IsNumeric(inputtext))return SendClientMessage(playerid, -1, "{FF0000}FEHLER: {FFFFFF} Gib eine gültige Objekt ID ein.");
    GateInfo[slot][GateModel] = strval(inputtext);
    ChangeObject(GateInfo[slot][GateObject], strval(inputtext));
    SaveServerGates(slot);
    format(string, sizeof(string),"{3399FF}INFO: {FFFFFF}Du hast das Model vom Tor (%i) erolgreich auf die ID %i geändert.", slot, strval(inputtext));
	return SendClientMessage(playerid, -1, string);
}

COMMAND:deletegate(playerid, params[]) {
	if(!Iter_Count(Gates))return SendClientMessage(playerid, -1, "{FF0000}FEHLER: {FFFFFF}Es wurden keine dynamischen Tore erstellt.");
	new Float:x, Float:y, Float:z, string[144];
	foreach(new i:Gates) {
		 GetDynamicObjectPos(GateInfo[i][GateObject], x, y, z);
		 if(!IsPlayerInRangeOfPoint(playerid, 5.0, x, y, z))continue;
		 SetPVarInt(playerid, "Delete:Gate:id", i);
		 SetPVarInt(playerid, "Delete:Gate:marker", CreateDynamicCP(x, y, z, 5.0));
		 format(string, sizeof(string),"Bist du dir sicher, dass du das angegebene Tor %s (%i) löschen möchtest?", GateInfo[i][GateName], i);
		 return Dialog_Show(playerid, GateDeleteMenu, DIALOG_STYLE_MSGBOX, "Dynamisches Tor: Löschen", string, "Bestätigen", "Abbrechen");
	}
	return 1;
}

Dialog:GateDeleteMenu(playerid, response, listitem, inputtext[]) {
	if(!response) {
	    DestroyDynamicCP(GetPVarInt(playerid, "Delete:Gate:marker"));
	    DeletePVar(playerid, "Delete:Gate:id");
	    DeletePVar(playerid, "Delete:Gate:marker");
		return 1;
	}
	new string[128];
	mysql_format(handler, string, sizeof(string),"DELETE FROM `gates` WHERE `id` = '%i'", GateInfo[GetPVarInt(playerid, "Delete:Gate:id")][DatabaseID]);
	mysql_pquery(handler, string);
	Iter_Remove(Gates, GetPVarInt(playerid, "Delete:Gate:id"));
	GateInfo[GetPVarInt(playerid, "Delete:Gate:id")][DatabaseID] = -1;
	format(string, sizeof(string), "{3399FF}INFO: {FFFFFF}Du hast das dynamische Tor %s (%i) erfolgreich gelöscht.",
	GateInfo[GetPVarInt(playerid, "Delete:Gate:id")][GateName], GetPVarInt(playerid, "Delete:Gate:id"));
	DestroyDynamicCP(GetPVarInt(playerid, "Delete:Gate:marker"));
 	DeletePVar(playerid, "Delete:Gate:id");
 	DeletePVar(playerid, "Delete:Gate:marker");
	return SendClientMessage(playerid, -1, string);
}

main()
{
	print("\n----------------------------------");
	print(" Dynamisches Torsystem (mit Ingame Editor)");
	print("----------------------------------\n");
}

public OnGameModeInit()
{
	// Don't use these lines if it's a filterscript
	SetGameModeText("Blank Script");
	AddPlayerClass(0, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
	
	handler =  mysql_connect("127.0.0.1", "root", "mypass", "mydatabase");
	
	mysql_pquery(handler, "SELECT * FROM `gates`;", "OnServerLoadGates");
	
	return 1;
}

public OnGameModeExit()
{
    SaveServerGates();
	return 1;
}

stock SaveServerGates(id=-1) {
	new query[32], mainquery[300];
	if(id != -1){
		format(query, sizeof(query),"UPDATE `gates` SET `gatename` = '%s',",GateInfo[id][GateName]);
		strcat(query, mainquery);
		format(query, sizeof(query),"`gatemodel` = '%s',",GateInfo[id][GateModel]);
		strcat(query, mainquery);
		format(query, sizeof(query),"`open:x` = '%s',",GateInfo[id][GateOpen][0]);
		strcat(query, mainquery);
		format(query, sizeof(query),"`open:y` = '%s',",GateInfo[id][GateOpen][1]);
		strcat(query, mainquery);
		format(query, sizeof(query),"`open:z` = '%s',",GateInfo[id][GateOpen][2]);
		strcat(query, mainquery);
		format(query, sizeof(query),"`open:rx` = '%s',",GateInfo[id][GateOpen][3]);
		strcat(query, mainquery);
		format(query, sizeof(query),"`open:ry` = '%s',",GateInfo[id][GateOpen][4]);
		strcat(query, mainquery);
		format(query, sizeof(query),"`open:rz` = '%s',",GateInfo[id][GateOpen][5]);
		strcat(query, mainquery);
		format(query, sizeof(query),"`close:x` = '%s',",GateInfo[id][GateClose][0]);
		strcat(query, mainquery);
		format(query, sizeof(query),"`close:y` = '%s',",GateInfo[id][GateClose][1]);
		strcat(query, mainquery);
		format(query, sizeof(query),"`close:z` = '%s',",GateInfo[id][GateClose][2]);
		strcat(query, mainquery);
		format(query, sizeof(query),"`close:rx` = '%s',",GateInfo[id][GateClose][3]);
		strcat(query, mainquery);
		format(query, sizeof(query),"`close:ry` = '%s',",GateInfo[id][GateClose][4]);
		strcat(query, mainquery);
		format(query, sizeof(query),"`close:rz` = '%s WHERE `id` = '%i'",GateInfo[id][GateClose][5], GateInfo[id][DatabaseID]);
		strcat(query, mainquery);
		return mysql_pquery(handler, mainquery);
	}
	foreach(new i:Gates) {
	    SaveServerGates(i);
	}
	return 1;
}

forward OnServerLoadGates();
public OnServerLoadGates() {
	new row, rows = 0;
	cache_get_row_count(rows);
	if(rows) {
		for(row = 0; row < rows; row++) {
		    cache_get_value_name_int(row, "id", GateInfo[row][DatabaseID]);
            cache_get_value_name(row, "gatename", GateInfo[row][GateName]);
            cache_get_value_name_int(row, "gatemodel", GateInfo[row][GateModel]);
            cache_get_value_name_float(row, "open:x", GateInfo[row][GateOpen][0]);
            cache_get_value_name_float(row, "open:y", GateInfo[row][GateOpen][1]);
            cache_get_value_name_float(row, "open:z", GateInfo[row][GateOpen][2]);
            cache_get_value_name_float(row, "open:rx", GateInfo[row][GateOpen][3]);
            cache_get_value_name_float(row, "open:ry", GateInfo[row][GateOpen][4]);
            cache_get_value_name_float(row, "open:rz", GateInfo[row][GateOpen][5]);
            cache_get_value_name_float(row, "close:x", GateInfo[row][GateClose][0]);
            cache_get_value_name_float(row, "close:y", GateInfo[row][GateClose][1]);
            cache_get_value_name_float(row, "close:z", GateInfo[row][GateClose][2]);
            cache_get_value_name_float(row, "close:rx", GateInfo[row][GateClose][3]);
            cache_get_value_name_float(row, "close:ry", GateInfo[row][GateClose][4]);
            cache_get_value_name_float(row, "close:rz", GateInfo[row][GateClose][5]);
            GateInfo[row][GateLocked] = true;
            GateInfo[row][GateObject] = CreateDynamicObject(GateInfo[row][GateModel], GateInfo[row][GateClose][0], GateInfo[row][GateClose][1], GateInfo[row][GateClose][2], GateInfo[row][GateClose][3], GateInfo[row][GateClose][4], GateInfo[row][GateClose][5]);
            Iter_Add(Gates, row);
		}
		printf("Es wurden %i dynamische Tor geladen.", rows);
	}
	return 1;
}

forward InsertGate(slot);
public InsertGate(slot) {
	GateInfo[slot][DatabaseID] = cache_insert_id();
	return 1;
}

stock ChangeObject(object, newmodel) {
	if(!IsValidDynamicObject(object))return 1;
	new
		Float:x, Float:y, Float:z,
		Float:rx, Float:ry, Float:rz;
	GetDynamicObjectPos(object, x, y, z);
	GetDynamicObjectPos(object, rx, ry, rz);
	DestroyDynamicObject(object);
	object = CreateDynamicObject(newmodel, x, y, z, rx, ry, rz);
	return 1;
}

public OnPlayerEditDynamicObject(playerid, objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz) {
    if(!IsValidDynamicObject(objectid)) return 1;
   	new slot = -1, string[144];
	if(GetPVarInt(playerid, "Create:Gate:step") != 0) {
		slot = GetPVarInt(playerid, "Create:Gate:id");
	 	if(objectid == GateInfo[slot][GateObject] && GetPVarInt(playerid, "Create:Gate:step") == 1) {
	 	    switch(response) {
		 		case EDIT_RESPONSE_CANCEL:{
	                SetDynamicObjectPos(objectid, GateInfo[slot][GateClose][0], GateInfo[slot][GateClose][1], GateInfo[slot][GateClose][2]);
		    		SetDynamicObjectPos(objectid, 0.00, 0.00, 0.00);
		    		SetPVarInt(playerid, "Create:Gate:step", 2);
		    		format(string, sizeof(string), "{3399FF}INFO: {FFFFFF}Du hast den geschlossenen Zustand des Tores (%i) positioniert.", slot);
		    		SendClientMessage(playerid, -1, string);
		    		EditDynamicObject(playerid, GateInfo[slot][GateObject]);
		    		return SendClientMessage(playerid, -1, "Du musst als nächstes den geöffneten Zustand des Tores positionieren.");
				}

		 	    case EDIT_RESPONSE_FINAL:{
		 	        GateInfo[slot][GateClose][0] = x;
					GateInfo[slot][GateClose][1] = y;
					GateInfo[slot][GateClose][2] = z;
					GateInfo[slot][GateClose][3] = rx;
					GateInfo[slot][GateClose][4] = ry;
					GateInfo[slot][GateClose][5] = rz;
	                SetDynamicObjectPos(objectid, x, y, z);
		    		SetDynamicObjectPos(objectid, rx, ry, rz);
		    		SetPVarInt(playerid, "Create:Gate:step", 2);
		    		format(string, sizeof(string), "{3399FF}INFO: {FFFFFF}Du hast den geschlossenen Zustand des Tores (%i) positioniert.", slot);
		    		SendClientMessage(playerid, -1, string);
		    		EditDynamicObject(playerid, GateInfo[slot][GateObject]);
		    		return SendClientMessage(playerid, -1, "Du musst als nächstes den geöffneten Zustand des Tores positionieren.");
				}
			}
		}
		else if(objectid == GateInfo[slot][GateObject] && GetPVarInt(playerid, "Create:Gate:step") == 2) {
	 	    switch(response) {
		 		case EDIT_RESPONSE_CANCEL:{
		 		    DeletePVar(playerid, "Create:Gate:id");
		 	        DeletePVar(playerid, "Create:Gate:step");
	                SetDynamicObjectPos(objectid, GateInfo[slot][GateOpen][0], GateInfo[slot][GateOpen][1], GateInfo[slot][GateOpen][2]);
		    		SetDynamicObjectPos(objectid, 0.00, 0.00, 0.00);
		    		format(string, sizeof(string), "{3399FF}INFO: {FFFFFF}Du hast den geöffneten Zustand des Tores (%i) positioniert.", slot);
		    		SaveServerGates(slot);
		    		return SendClientMessage(playerid, -1, string);
				}

		 	    case EDIT_RESPONSE_FINAL:{
		 	        DeletePVar(playerid, "Create:Gate:id");
		 	        DeletePVar(playerid, "Create:Gate:step");
		 	        GateInfo[slot][GateOpen][0] = x;
					GateInfo[slot][GateOpen][1] = y;
					GateInfo[slot][GateOpen][2] = z;
					GateInfo[slot][GateOpen][3] = rx;
					GateInfo[slot][GateOpen][4] = ry;
					GateInfo[slot][GateOpen][5] = rz;
	                SetDynamicObjectPos(objectid, x, y, z);
		    		SetDynamicObjectPos(objectid, rx, ry, rz);
		    		format(string, sizeof(string), "{3399FF}INFO: {FFFFFF}Du hast den geöffneten Zustand des Tores (%i) positioniert.", slot);
		    		SaveServerGates(slot);
		    		return SendClientMessage(playerid, -1, string);
				}
			}
		}
	}
	if(GetPVarInt(playerid, "Edit:Gate:Type") != 0) {
        slot = GetPVarInt(playerid, "Edit:Gate:id");
		if(objectid == GateInfo[slot][GateObject]) {
        	switch(response) {
		 		case EDIT_RESPONSE_CANCEL:{
		 		    DeletePVar(playerid, "Edit:Gate:Type");
		 	        DeletePVar(playerid, "Edit:Gate:id");
		 		    SetDynamicObjectPos(objectid, GateInfo[slot][GateClose][0], GateInfo[slot][GateClose][1], GateInfo[slot][GateClose][2]);
		    		SetDynamicObjectPos(objectid, GateInfo[slot][GateClose][3], GateInfo[slot][GateClose][4], GateInfo[slot][GateClose][5]);
		    		GateInfo[slot][GateLocked] = true;
		    		return SendClientMessage(playerid, -1, "{3399FF}INFO: {FFFFFF}Du hast die Bearbeitung des Tores abgebrochen!");
				}

		 	    case EDIT_RESPONSE_FINAL:{
		 	        if(GetPVarInt(playerid, "Edit:Gate:Type") == 1){
                        GateInfo[slot][GateClose][0] = x,GateInfo[slot][GateClose][1] = y,GateInfo[slot][GateClose][2] = z;
						GateInfo[slot][GateClose][3] = rx,GateInfo[slot][GateClose][4] = ry,GateInfo[slot][GateClose][5] = rz;
					} else {
			 	        GateInfo[slot][GateOpen][0] = x,GateInfo[slot][GateOpen][1] = y,GateInfo[slot][GateOpen][2] = z;
						GateInfo[slot][GateOpen][3] = rx,GateInfo[slot][GateOpen][4] = ry,GateInfo[slot][GateOpen][5] = rz;
					}
		    		format(string, sizeof(string), "{3399FF}INFO: {FFFFFF}Du hast den %s Zustand des Tores (%i) positioniert.",
					((GetPVarInt(playerid, "Edit:Gate:Type") == 1) ? ("geschlossenen") : ("geöffneten") ) ,slot);
		    		DeletePVar(playerid, "Edit:Gate:Type");
		 	        DeletePVar(playerid, "Edit:Gate:id");
		 	        SetDynamicObjectPos(objectid, GateInfo[slot][GateClose][0], GateInfo[slot][GateClose][1], GateInfo[slot][GateClose][2]);
		    		SetDynamicObjectPos(objectid, GateInfo[slot][GateClose][3], GateInfo[slot][GateClose][4], GateInfo[slot][GateClose][5]);
		    		SaveServerGates(slot);
		    		return SendClientMessage(playerid, -1, string);
				}
			}
		}
	}
	return 1;
}
