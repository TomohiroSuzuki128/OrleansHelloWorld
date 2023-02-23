using Microsoft.Extensions.Logging;
using System.Threading.Tasks;

namespace OrleansPoc
{
    public class HelloGrain : Orleans.Grain, IHello
    {
        private readonly ILogger _logger;

        public HelloGrain(ILogger<HelloGrain> logger)
        {
            _logger = logger;
        }

        Task<string> IHello.Call()
        {
            _logger.LogInformation($"\n{DateTime.Now} Call recieved.");
            return Task.FromResult($"\n{DateTime.Now} Call recieved.");
        }

        Task<string> IHello.SayHello(string greeting)
        {
            _logger.LogInformation($"{DateTime.Now} SayHello message received: greeting = '{greeting}'");
            return Task.FromResult($"\n{DateTime.Now}  Client said: '{greeting}', so HelloGrain says: Hello!");
        }

        Task<string> IHello.Deactivate()
        {
            DeactivateOnIdle();
            return Task.FromResult($"{DateTime.Now} Grain status : HelloGrain({IdentityString}) is deactivated...");
        }

        public override Task OnActivateAsync(CancellationToken cancellationToken)
        {
            _logger.LogInformation($"{DateTime.Now} Grain status : HelloGrain({IdentityString}) is activating...");
            return base.OnActivateAsync(cancellationToken);
        }

        public override Task OnDeactivateAsync(DeactivationReason reason, CancellationToken cancellationToken)
        {
            _logger.LogInformation($"{DateTime.Now} Grain status : HelloGrain({IdentityString}) is deactivating...");
            return base.OnDeactivateAsync(reason, cancellationToken);
        }
    }
}