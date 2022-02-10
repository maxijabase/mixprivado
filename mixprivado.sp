#include <autoexecconfig>
#include <regex>
#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define PREFIX "[MixPrivado]"

public Plugin myinfo = {
	name = "[TF2] Mix Privado", 
	author = "ampere", 
	description = "Whitelist para usar en mixes privados", 
	version = PLUGIN_VERSION, 
	url = "https://github.com/maxijabase"
};

ConVar g_cvEnabled;
char g_cConfigFile[PLATFORM_MAX_PATH];
ArrayList g_alPlayers;

/* Forwards */

public void OnPluginStart() {
	
	AutoExecConfig_SetCreateFile(true);
	AutoExecConfig_SetFile("MixPrivado");
	
	g_cvEnabled = AutoExecConfig_CreateConVar("sm_mp_enable", "1", "Activar Mix Privado");
	
	RegAdminCmd("sm_mp_list", CMD_List, ADMFLAG_GENERIC, "Ver la whitelist.");
	RegAdminCmd("sm_mp_reload", CMD_Reload, ADMFLAG_GENERIC, "Recargar whitelist.");
	RegAdminCmd("sm_mp_add", CMD_Add, ADMFLAG_GENERIC, "Agregar una Steam ID a la whitelist.");
	
	CacheUsers();
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
}

public void OnClientAuthorized(int client, const char[] auth) {
	
	if (!g_cvEnabled.BoolValue) {
		
		return;
		
	}
	
	char steamid[18];
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
	
	if (g_alPlayers.FindString(steamid) == -1) {
		
		KickClient(client, "No estás en la whitelist de mix privado.");
		
	}
	
}

/* Commands */

public Action CMD_Reload(int client, int args) {
	
	CacheUsers(client == 0 ? -1 : GetClientUserId(client));
	return Plugin_Handled;
	
}

public Action CMD_Add(int client, int args) {
	
	if (args != 1) {
		
		ReplyToCommand(client, "%s Uso: sm_mp_add <STEAMID64>", PREFIX);
		return Plugin_Handled;
		
	}
	
	char arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	
	if (!SimpleRegexMatch(arg, "^7656119[0-9]{10}$")) {
		
		ReplyToCommand(client, "%s Steam ID inválido.", PREFIX);
		return Plugin_Handled;
	}
	
	AddUser(arg, client);
	return Plugin_Handled;
	
}

public Action CMD_List(int client, int args) {
	
	int alLength = g_alPlayers.Length;
	
	if (alLength == 0) {
		ReplyToCommand(client, "%s La whitelist está vacía", PREFIX);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < alLength; i++) {
		char buffer[64];
		g_alPlayers.GetString(i, buffer, sizeof(buffer));
		ReplyToCommand(client, "%s", buffer);
	}
	
	return Plugin_Handled;
}

/* Methods */

void CacheUsers(int userid = -1) {
	
	if (userid != -1) {
		ReplyToCommand(GetClientOfUserId(userid), "%s Recargando whitelist...", PREFIX);
	}
	
	BuildPath(Path_SM, g_cConfigFile, sizeof(g_cConfigFile), "configs/MixPrivadoWhitelist.cfg");
	
	if (!FileExists(g_cConfigFile)) {
		
		File file = OpenFile(g_cConfigFile, "w");
		
		if (!file) {
			
			SetFailState("%s Error al intentar crear la whitelist.", PREFIX);
			
		}
		
		file.WriteLine("// Mix Privado Whitelist");
		file.WriteLine("");
		
		delete file;
		
		if (userid != -1) {
			ReplyToCommand(GetClientOfUserId(userid), "%s La whitelist no existía y se creó.", PREFIX);
		}
		
		return;
		
	}
	
	File file = OpenFile(g_cConfigFile, "r");
	
	if (!file) {
		SetFailState("%s Error al procesar la whitelist.", PREFIX);
	}
	
	char readBuffer[128];
	int len;
	
	if (userid == -1) {
		
		g_alPlayers = new ArrayList();
		
	}
	
	else {
		
		g_alPlayers.Clear();
		
	}
	
	
	while (!file.EndOfFile() && file.ReadLine(readBuffer, sizeof(readBuffer))) {
		
		if (readBuffer[0] == '/' || readBuffer[0] == ' ') {
			
			continue;
			
		}
		
		len = strlen(readBuffer);
		
		for (int i; i < len; i++) {
			
			if (readBuffer[i] == ' ' || readBuffer[i] == '/') {
				
				readBuffer[i] = '\0';
				len = strlen(readBuffer);
				
				break;
				
			}
			
		}
		
		PrintToServer("adding %s", readBuffer);
		g_alPlayers.PushString(readBuffer);
		
	}
	
	if (userid != -1) {
		ReplyToCommand(GetClientOfUserId(userid), "%s Whitelist recargada.", PREFIX);
	}
	
	delete file;
	
}

void AddUser(const char[] steamid, int client) {
	
	File file = OpenFile(g_cConfigFile, "a");
	
	if (!file) {
		
		ReplyToCommand(client, "%s Error al abrir el archivo para agregar usuario.", PREFIX);
		delete file;
		return;
		
	}
	
	file.WriteLine(steamid, true);
	g_alPlayers.PushString(steamid);
	
	ReplyToCommand(client, "%s %s agregado.", PREFIX, steamid);
	
	delete file;
	return;
	
} 