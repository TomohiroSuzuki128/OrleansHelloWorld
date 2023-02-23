using System.Net;
using Orleans.Configuration;
using OrleansPoc;

var siloHost = await StartSiloAsync();

var clientHost = await StartClientAsync();
var client = clientHost.Services.GetRequiredService<IClusterClient>();
var friend = client.GetGrain<IHello>(0);
var zipToAddress = client.GetGrain<ISearchAddress>(0);
var writeLargeData = client.GetGrain<IWriteLargeData>(0);

var app = WebApplication.Create();
app.MapGet("/", async () => await friend.Call());
app.MapGet("/hello", async () => await friend.SayHello($"Konnichiwa!!"));
app.MapGet("/deactivate", async () => await friend.Deactivate());
app.MapGet("/ziptoaddress/{zipCode}", async (string zipCode) => await zipToAddress.GetAddress($"{zipCode}"));
app.MapGet("/writelargedata", async () => await writeLargeData.WriteLargeData());
await app.RunAsync();

static async Task<IHost> StartClientAsync()
{
    var connectionString = Environment.GetEnvironmentVariable("ORLEANS_AZURE_STORAGE_CONNECTION_STRING");

    var builder = new HostBuilder()
        .UseOrleansClient(client =>
        {
            client
                .UseAzureStorageClustering(
                    options => options.ConfigureTableServiceClient(connectionString))
                .Configure<ClusterOptions>(options =>
                {
                    options.ClusterId = "PoCCluster";
                    options.ServiceId = "OrleansPoC";
                });
        })
        .ConfigureLogging(logging => logging.AddConsole());

    var host = builder.Build();
    await host.StartAsync();
    return host;
}

static async Task<IHost> StartSiloAsync()
{
    var builder = Host.CreateDefaultBuilder()
        .UseOrleans(
            (context, builder) =>
            {
                var siloIPAddress = IPAddress.Parse(context.Configuration["WEBSITE_PRIVATE_IP"] ?? "");

                // WEBSITE_PRIVATE_PORTS は再起動で変更されるのでWEBSITE_PRIVATE_PORTS として取得し Parse すること
                var strPorts = (context.Configuration["WEBSITE_PRIVATE_PORTS"] ?? "").Split(',');
                if (strPorts.Length < 2)
                    throw new Exception("Insufficient private ports configured.");
                var (siloPort, gatewayPort) = (int.Parse(strPorts[0]), int.Parse(strPorts[1]));
                var connectionString =
                    context.Configuration["ORLEANS_AZURE_STORAGE_CONNECTION_STRING"];

                builder
                    .ConfigureEndpoints(siloIPAddress, siloPort, gatewayPort)
                    .Configure<ClusterOptions>(
                        options =>
                        {
                            options.ClusterId = "PoCCluster";
                            options.ServiceId = "OrleansPoC";
                        })
                    .UseAzureStorageClustering(
                    options => options.ConfigureTableServiceClient(connectionString))
                    .AddAzureTableGrainStorage(
                        "PocStore",
                     options => options.ConfigureTableServiceClient(connectionString)
                     )
                    .ConfigureLogging(logging => logging.AddConsole());
            });

    var host = builder.Build();
    await host.StartAsync();

    return host;
}