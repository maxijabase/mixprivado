#include <autoexecconfig>
#include <sdktools>
#include <smset>
#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define PREFIX "[MixPrivado]"

public Plugin myinfo = 
{
	name = "[TF2] Mix Privado", 
	author = "ampere", 
	description = "Whitelist para usar en mixes privados", 
	version = PLUGIN_VERSION, 
	url = "https://github.com/maxijabase"
};

ConVar g_cvEnabled;
char g_cConfigFile[PLATFORM_MAX_PATH];
StringSet g_ssPlayers;

public void OnPluginStart() {
	
	AutoExecConfig_SetCreateFile(true);
	AutoExecConfig_SetFile("MixPrivado");
	
	g_cvEnabled = AutoExecConfig_CreateConVar("sm_mp_enable", "1", "Activar Mix Privado");
	RegConsoleCmd("sm_testlist", CMD_Testlist);
	
	RegAdminCmd("sm_mp_reload", CMD_Reload, ADMFLAG_GENERIC, "Reload whitelist.");
	RegAdminCmd("sm_mp_add", CMD_Add, ADMFLAG_GENERIC, "Add an ID to whitelist.");
	
	CacheUsers();
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
}

void CacheUsers(int userid = -1) {
	
	if (userid != -1) {
		ReplyToCommand(GetClientOfUserId(userid), "%s Reloading whitelist...", PREFIX);
	}
	
	BuildPath(Path_SM, g_cConfigFile, sizeof(g_cConfigFile), "configs/MixPrivadoWhitelist.cfg");
	
	if (!FileExists(g_cConfigFile)) {
		
		File file = OpenFile(g_cConfigFile, "w");
		
		if (!file) {
			
			SetFailState("%s Error while trying to make the whitelist file!", PREFIX);
			
		}
		
		file.WriteLine("// Mix Privado Whitelist");
		file.WriteLine("");
		
		delete file;
		
		if (userid != -1) {
			ReplyToCommand(GetClientOfUserId(userid), "%s Whitelist was not present, created.", PREFIX);
		}
		
		return;
		
	}
	
	File file = OpenFile(g_cConfigFile, "r");
	
	if (!file) {
		SetFailState("%s Error while attempting to parse the config file!", PREFIX);
	}
	
	char readBuffer[128];
	int len;
	g_ssPlayers = new StringSet();
	
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
		
		g_ssPlayers.Insert(readBuffer);
		
	}
	
	if (userid != -1) {
		ReplyToCommand(GetClientOfUserId(userid), "%s Whitelist reloaded.", PREFIX);
	}
	
	delete file;
	
}

/* Forwards */

public void OnClientAuthorized(int client, const char[] auth) {
	
	if (!g_cvEnabled.BoolValue) {
		
		return;
		
	}
	
	char steamid[18];
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
	
	if (!g_ssPlayers.Find(steamid)) {
		
		KickClient(client, "No estás en la whitelist de mix privado.");
		
	}
	
}

/* Commands */

public Action CMD_Reload(int client, int args) {
	
	CacheUsers(client == 0 ? -1 : GetClientUserId(client));
	return Plugin_Handled;
	
}

public Action CMD_Add(int client, int args) {
	
	return Plugin_Handled;
	
}

public Action CMD_Testlist(int client, int args) {
	
	StringSetIterator siter = g_ssPlayers.Iterator();
	while (siter.Next())
	{
		char buffer2[32];
		siter.Get(buffer2, sizeof(buffer2));
		ReplyToCommand(client, "%s", buffer2);
	}
	
	delete siter;
	
}
