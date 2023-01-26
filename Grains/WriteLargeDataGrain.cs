using Grains.Status;
using Microsoft.Extensions.Logging;
using OrleansPoc.Sevices;
using System.Reflection.Emit;
using System.Threading.Tasks;
using Orleans.Runtime;

namespace OrleansPoc
{
    public class WriteLargeDataGrain : Orleans.Grain, IWriteLargeData
    {
        private readonly ILogger _logger;
        private readonly IPersistentState<WriteLargeDataState> _largeData;

        public WriteLargeDataGrain(
            [PersistentState("largeData", "PocStore")] IPersistentState<WriteLargeDataState> largeData,
            ILogger<HelloGrain> logger
            )
        {
            _largeData = largeData;
            _logger = logger;
        }

        async Task<string> IWriteLargeData.WriteLargeData()
        {
            _logger.LogInformation($"\n{DateTime.Now} WriteLargeData recieved.");

            var largeData = "";
            largeData = Enumerable.Range(0, 30000).Select(i => "ABCDEFGHIJKLMNOPQRSTUVWXYZ").Aggregate((x, y) => $"{x},{y}");

            _largeData.State.LargeData = largeData;
            await _largeData.WriteStateAsync();

            return "Grain Status の書き込みが終了しました。";
        }

    }
}