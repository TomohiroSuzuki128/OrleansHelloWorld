using System.Threading.Tasks;
using Orleans;

namespace OrleansPoc
{
    public interface IHello : Orleans.IGrainWithGuidKey
    {
        Task<string> Call();
        Task<string> SayHello(string greeting);
        Task<string> Deactivate();
    }
}
