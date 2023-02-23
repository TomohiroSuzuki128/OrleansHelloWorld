using System.Net;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Orleans.Configuration;

try
{
    var host = await StartSiloAsync();
    Console.WriteLine("\n\n Press Enter to terminate...\n\n");
    Console.ReadLine();

    await host.StopAsync();

    return 0;
}
catch (Exception ex)
{
    Console.WriteLine(ex);
    return 1;
}

static async Task<IHost> StartSiloAsync()
{
    var builder = Host.CreateDefaultBuilder()
        .UseOrleans(
            (context, builder) =>
            {
                var siloIPAddress = IPAddress.Parse(context.Configuration["WEBSITE_PRIVATE_IP"] ?? "");

                if (context.Configuration["ENVIRONMENT"] == "Development")
                {
                    var connectionString =
                        context.Configuration["ORLEANS_AZURE_STORAGE_CONNECTION_STRING"];

                    builder
                        //.UseLocalhostClustering()
                        .UseAzureStorageClustering(
                            options => options.ConfigureTableServiceClient(connectionString))

                        .Configure<ClusterOptions>(options =>
                        {
                            options.ClusterId = "PoCCluster";
                            options.ServiceId = "OrleansPoC";
                        })
                        .AddAzureTableGrainStorage(
                            "PocStore",
                             options => options.ConfigureTableServiceClient(connectionString)
                        );
                }
                else
                {
                    int.TryParse(context.Configuration["ORLEANS_SILO_PORT"], out int siloPort);
                    int.TryParse(context.Configuration["ORLEANS_GATEWAY_PORT"], out int gatewayPort);
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
                }
            });

    var host = builder.Build();
    await host.StartAsync();

    return host;
}