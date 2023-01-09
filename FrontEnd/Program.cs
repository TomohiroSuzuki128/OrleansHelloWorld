using Orleans.Configuration;
using OrleansBasics;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.AspNetCore.Builder;
using System;

try
{
    var host = await StartClientAsync();
    var client = host.Services.GetRequiredService<IClusterClient>();
    var friend = client.GetGrain<IHello>(0);
    var zipToAddress = client.GetGrain<ISearchAddress>(0);

    var app = WebApplication.Create();
    app.MapGet("/", async () => await friend.Call());
    app.MapGet("/hello", async () => await friend.SayHello($"Konnichiwa!!"));
    app.MapGet("/deactivate", async () => await friend.Deactivate());
    app.MapGet("/ziptoaddress/{zipCode}", async (string zipCode) => await zipToAddress.GetAddress($"{zipCode}"));
    await app.RunAsync();

    Console.ReadKey();

    return 0;
}
catch (Exception e)
{
    Console.WriteLine($"\nException while trying to run client: {e.Message}");
    Console.WriteLine("Make sure the silo the client is trying to connect to is running.");
    Console.WriteLine("\nPress any key to exit.");
    Console.ReadKey();
    return 1;
}

static async Task<IHost> StartClientAsync()
{
    var connectionString = Environment.GetEnvironmentVariable("ORLEANS_AZURE_STORAGE_CONNECTION_STRING"); 

    var builder = new HostBuilder()
        .UseOrleansClient(client =>
        {
            client
                //.UseLocalhostClustering()
                .UseAzureStorageClustering(
                    options => options.ConfigureTableServiceClient(connectionString))
                .Configure<ClusterOptions>(options =>
                {
                    options.ClusterId = "PoCCluster";
                    options.ServiceId = "OrleansBasics";
                });
        })
        .ConfigureLogging(logging => logging.AddConsole());

    var host = builder.Build();
    await host.StartAsync();

    Console.WriteLine("Client successfully connected to silo host \n");

    return host;
}