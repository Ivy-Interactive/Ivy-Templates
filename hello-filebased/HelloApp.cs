#:package Ivy@*

using Ivy;
using Ivy.Shared;
using Ivy.Views;
using Ivy.Widgets.Inputs;

var server = new Server();
server.AddApp<HelloApp>();
await server.RunAsync();

[App]
public class HelloApp : ViewBase
{
    public override object? Build()
    {
        var name = UseState<string>();

        return Layout.Center() |
            new Card(
                Layout.Vertical() |
                    Text.H2("Hello " + (string.IsNullOrEmpty(name.Value) ? "there" : name.Value) + "!") |
                    name.ToInput(placeholder: "What is your name?")
            ).Width(Size.Units(120));
    }
}
