using Hello.Apps;
var server = new Server();
server.UseCulture("en-US");
#if DEBUG
server.UseHotReload();
#endif
server.AddAppsFromAssembly();
server.AddConnectionsFromAssembly();
var chromeSettings = new ChromeSettings().DefaultApp<HelloApp>().UseTabs(preventDuplicates: true);
server.UseChrome(chromeSettings);
await server.RunAsync();
