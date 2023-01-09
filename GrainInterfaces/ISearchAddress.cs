using System.Threading.Tasks;
using Orleans;

namespace OrleansBasics
{
    public interface ISearchAddress : Orleans.IGrainWithIntegerKey
    {
        Task<string> GetAddress(string zipCode);
    }
}
