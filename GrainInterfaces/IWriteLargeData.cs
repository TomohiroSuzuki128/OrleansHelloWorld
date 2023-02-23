using System.Threading.Tasks;
using Orleans;

namespace OrleansPoc
{
    public interface IWriteLargeData : Orleans.IGrainWithIntegerKey
    {
        Task<string> WriteLargeData();
    }
}
