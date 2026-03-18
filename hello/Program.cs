using Ivy;
using Hello.Apps;

var server = new Server();
server.UseCulture("en-US");
#if DEBUG
server.UseHotReload();
#endif
server.AddAppsFromAssembly();
server.AddConnectionsFromAssembly();
server.UseChrome(new ChromeSettings().DefaultApp<HelloApp>().UseTabs(preventDuplicates: true));
await server.RunAsync();
