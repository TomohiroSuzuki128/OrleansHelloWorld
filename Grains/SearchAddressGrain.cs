using Grains.Status;
using Microsoft.Extensions.Logging;
using OrleansBasics.Sevices;
using System.Reflection.Emit;
using System.Threading.Tasks;
using Orleans.Runtime;

namespace OrleansBasics
{
    public class SearchAddressGrain : Orleans.Grain, ISearchAddress
    {
        private readonly ILogger _logger;
        private readonly IPersistentState<ValidZipCodeState> _validZipCodes;

        public SearchAddressGrain(
            [PersistentState("validZipCode", "ValidZipCodeStore")] IPersistentState<ValidZipCodeState> validZipCodes,
            ILogger<HelloGrain> logger
            )
        {
            _validZipCodes = validZipCodes;
            _logger = logger;
        }

        async Task<string> ISearchAddress.GetAddress(string zipCode)
        {
            _logger.LogInformation($"\n{DateTime.Now} GetAddress recieved.");

            var trimmedZipCode = zipCode.Replace("-", "");
            var addresses = await SearchAddressClient.ZipToAddress(trimmedZipCode);

            if (addresses.Length > 0)
            {
                var address = addresses.FirstOrDefault();
                _validZipCodes.State.ValidZipCodes.Add(new(trimmedZipCode));

                await _validZipCodes.WriteStateAsync();
                return address.ToString();
            }
            return "該当する住所が見つかりません";
        }

    }
}