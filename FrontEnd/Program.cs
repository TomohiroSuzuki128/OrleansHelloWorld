using Orleans.Configuration;
using OrleansPoc;

var host = await StartClientAsync();
var client = host.Services.GetRequiredService<IClusterClient>();
var hello = client.GetGrain<IHello>(Guid.NewGuid());
var zipToAddress = client.GetGrain<ISearchAddress>(Guid.NewGuid());
var writeLargeData = client.GetGrain<IWriteLargeData>(Guid.NewGuid());

var app = WebApplication.Create();
app.MapGet("/", async () => await hello.Call());
app.MapGet("/hello", async () => await hello.SayHello($"Konnichiwa!!"));
app.MapGet("/deactivate", async () => await hello.Deactivate());
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
                //.UseLocalhostClustering()
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

    //Console.WriteLine("Client successfully connected to silo host \n");

    return host;
}