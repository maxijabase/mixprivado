#include <sourcemod>
#include <sdktools>

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

char g_cConfigFile[PLATFORM_MAX_PATH];
StringMap g_smPlayers;

public void OnPluginStart()
{
	RegConsoleCmd("sm_testlist", CMD_Testlist);
	
	RegAdminCmd("sm_mp_reload", CMD_Reload, ADMFLAG_GENERIC, "Reload whitelist.");
	RegAdminCmd("sm_mp_add", CMD_Add, ADMFLAG_GENERIC, "Add an ID to whitelist.");
	
	CacheUsers();
	
}

void CacheUsers(int userid = -1) {
	
	if (userid != -1) {
		PrintToChat(GetClientOfUserId(userid), "%s Reloading whitelist...", PREFIX);
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
			PrintToChat(GetClientOfUserId(userid), "%s Whitelist was not present, created.", PREFIX);
		}
		return;
		
	}
	
	File file = OpenFile(g_cConfigFile, "r");
	
	if (!file) {
		SetFailState("%s Error while attempting to parse the config file!", PREFIX);
	}
	
	char readBuffer[128];
	int len;
	g_smPlayers = new ArrayList(ByteCountToCells(32));
	
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
		
		g_smPlayers.(readBuffer);
		
	}
	
	if (userid != -1) {
		PrintToChat(GetClientOfUserId(userid), "%s Whitelist reloaded.", PREFIX);
	}
	
	delete file;
	
}

public void OnClientAuthorized(int client, const char[] auth) {
	
	
}

public Action CMD_Reload(int client, int args) {
	
	CacheUsers(GetClientUserId(client));
	return Plugin_Handled;
	
}

public Action CMD_Add(int client, int args) {
	return Plugin_Handled;
}

public Action CMD_Testlist(int client, int args) {
	char buffer[32];
	for (int i = 0; i < g_smPlayers.Length; i++) {
		g_smPlayers.GetString(i, buffer, sizeof(buffer));
		PrintToChat(client, buffer);
	}
	
}
