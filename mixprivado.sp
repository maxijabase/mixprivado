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
ArrayList g_alPlayers;

public void OnPluginStart()
{
	CacheUsers();
	RegConsoleCmd("sm_testlist", CMD_Testlist);
}

void CacheUsers() {
	
	BuildPath(Path_SM, g_cConfigFile, sizeof(g_cConfigFile), "configs/MixPrivadoWhitelist.cfg");
	
	if (!FileExists(g_cConfigFile)) {
		
		File file = OpenFile(g_cConfigFile, "w");
		
		if (!file) {
			
			SetFailState("%s Error while trying to make the whitelist file!", PREFIX);
			
		}
		
		file.WriteLine("// Mix Privado Whitelist");
		file.WriteLine("");
		
		delete file;
		return;
		
	}
	
	File file = OpenFile(g_cConfigFile, "r");
	
	if (!file) {
		
		SetFailState("%s Error while attempting to parse the config file!", PREFIX);
		
	}
	
	char readBuffer[128];
	int len;
	g_alPlayers = new ArrayList(ByteCountToCells(32));
	
	while (!file.EndOfFile() && file.ReadLine(readBuffer, sizeof(readBuffer))) {
		
		if (readBuffer[0] == '/' || IsCharSpace(readBuffer[0])) {
			
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
		
		g_alPlayers.PushString(readBuffer);
		
	}
	
	delete file;
	
}

public Action CMD_Testlist(int client, int args) {
	char buffer[32];
	for(int i = 0; i < g_alPlayers.Length; i++) {
		g_alPlayers.GetString(i, buffer, sizeof(buffer));
		PrintToChat(client, buffer);
	}
	
}
