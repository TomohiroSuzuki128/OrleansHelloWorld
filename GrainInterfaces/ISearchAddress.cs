using System.Threading.Tasks;
using Orleans;

namespace OrleansPoc
{
    public interface ISearchAddress : Orleans.IGrainWithIntegerKey
    {
        Task<string> GetAddress(string zipCode);
    }
}
