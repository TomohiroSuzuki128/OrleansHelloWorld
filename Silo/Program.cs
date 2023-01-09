using System;
using System.Net;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Orleans.Configuration;
using Orleans.Hosting;
using Orleans.Runtime;

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
    //var connectionString = "YOUR_CONNECTION_STRING_HERE";
    //var primarySiloEndpoint = new IPEndPoint(PRIMARY_SILO_IP_ADDRESS, 11111);

    var builder = Host.CreateDefaultBuilder()
        .UseOrleans(
            (context, builder) =>
            {
                var siloIPAddress = IPAddress.Parse(context.Configuration["WEBSITE_PRIVATE_IP"]);
                var siloPort = 11111;
                var gatewayPort = 52155;

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
                            options.ServiceId = "OrleansBasics";
                        })
                        //.AddMemoryGrainStorage("OrleansDevStorage");
                        .AddAzureTableGrainStorage(
                            "ValidZipCodeStore",
                             options => options.ConfigureTableServiceClient(connectionString)
                        );
                }
                else
                {

                    var strPorts =
                        context.Configuration["WEBSITE_PRIVATE_PORTS"].Split(',');
                    if (strPorts.Length < 2)
                        throw new Exception("Insufficient private ports configured.");
                    //var (siloPort, gatewayPort) =
                    //    (int.Parse(strPorts[0]), int.Parse(strPorts[1]));
                    var connectionString =
                        context.Configuration["ORLEANS_AZURE_STORAGE_CONNECTION_STRING"];

                    builder
                        .ConfigureEndpoints(siloIPAddress, siloPort, gatewayPort)
                        .Configure<ClusterOptions>(
                            options =>
                            {
                                options.ClusterId = "PoCCluster";
                                options.ServiceId = "OrleansBasics";
                                //options.ServiceId = nameof(ShoppingCartService);
                            })
                        .UseAzureStorageClustering(
                        options => options.ConfigureTableServiceClient(connectionString))
                        .AddAzureTableGrainStorage(
                            "ValidZipCodeStore",
                         options => options.ConfigureTableServiceClient(connectionString)
                         )
                        .ConfigureLogging(logging => logging.AddConsole());
                }
            });

    var host = builder.Build();
    await host.StartAsync();

    return host;
}