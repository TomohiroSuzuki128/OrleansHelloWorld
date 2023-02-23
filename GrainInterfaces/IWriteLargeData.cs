using System.Threading.Tasks;
using Orleans;

namespace OrleansPoc
{
    public interface IWriteLargeData : Orleans.IGrainWithGuidKey
    {
        Task<string> WriteLargeData();
    }
}
