using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;

// HttpClient is intended to be instantiated once per application, rather than per-use.
HttpClient httpClient = new (new HttpClientHandler
{
    MaxConnectionsPerServer = 2
});
//string uri = "http://localhost:12276/hello";
string baseUri = "http://localhost:12276/ziptoaddress/";
ParallelOptions parallelOptions = new()
{
    MaxDegreeOfParallelism = 2
};
await PerformLoadTestAsync(parallelOptions, httpClient, baseUri);

static async Task PerformLoadTestAsync(ParallelOptions parallelOptions, HttpClient httpClient, string baseUri)
{
    var sw = Stopwatch.StartNew();
    await Parallel.ForEachAsync(Enumerable.Range(0, 500000), parallelOptions, async (o, token) =>
    {
        var uri = baseUri + RandomZipCode();
        await SendHttpRequest(o, httpClient, uri);
        Console.WriteLine($"Try : {o.ToString("000000")} : {uri}");
    });
    Console.WriteLine($"\nElapsed:{sw.ElapsedMilliseconds}\n\n");
}

static async Task SendHttpRequest(int o, HttpClient httpClient, string uri)
{
    // 10リクエスト並列で投げる。それぞれは10回試行
    // 並列
    var tasks = Enumerable.Range(0, 1).Select(async idx => 
    {
        // 試行
        for (int i = 0; i < 10; i++)
        {
            try
            {
                var request = new HttpRequestMessage
                {
                    Method = HttpMethod.Get,
                    RequestUri = new Uri(uri)
                };
                var response = await httpClient.SendAsync(request);
                if ((int)response.StatusCode < 200 || (int)response.StatusCode >= 300)
                {
                    throw new Exception($"HTTP Status NG : {response.StatusCode}");
                }
                var responseText = await response.Content.ReadAsStringAsync();
                Console.WriteLine($"HTTP Status OK : {o},{idx},{i} : {responseText} : {uri}");
                break;
            }
            catch (Exception e)
            {
                Console.WriteLine($"error : {o},{idx},{i}) : {e}");
            }
        }
    });
    await Task.WhenAll(tasks).ConfigureAwait(false);
    Console.WriteLine($"done : {o}");
}

static string RandomZipCode()
{
    var zipCode = String.Empty;
    var r = new Random((int)DateTime.Now.Ticks);
    zipCode += (r.Next(9) + 1).ToString();
    zipCode += string.Join("", Enumerable.Range(0, 6).Select(i =>
    {
        return r.Next(10).ToString();
    }));
    return zipCode;
}
