using System.Threading.Tasks;
using Orleans;

namespace OrleansPoc
{
    public interface ISearchAddress : Orleans.IGrainWithGuidKey
    {
        Task<string> GetAddress(string zipCode);
    }
}
